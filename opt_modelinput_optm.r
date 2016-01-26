# optm core part
print("Note: Extrating Optimization Setup Parameters")
# optm pace
spend_inc=ex.setup$input_increment 
value.inc.threshold=ex.setup$input_goal_check

# optm type
if (ex.setup$optimization_type==2) {
  budget=max.level
  goal=ex.setup$optimization_type_value
  goal.seek=1
}else if (ex.setup$optimization_type==1){
  budget=ex.setup$optimization_type_value
  goal=max.level
  goal.seek=0
}else if (ex.setup$optimization_type==5){
  budget=ex.setup$optimization_type_value
  goal=max.level
  goal.seek=0
}else if (ex.setup$optimization_type==6){
  budget=max.level
  goal=ex.setup$optimization_type_value
  goal.seek=1
}else if (ex.setup$optimization_type==3){
  budget=ex.setup$optimization_type_value
  goal=max.level
  goal.seek=0
}else if (ex.setup$optimization_type==4){
  budget=0
  goal=max.level
  goal.seek=0
}else if (ex.setup$optimization_type==7){
  budget=max.level
  goal=ex.setup$optimization_type_value
  goal.seek=1
}else if (ex.setup$optimization_type==8){
  budget=max.level
  goal=max.level
  goal.seek=0
}else if (ex.setup$optimization_type==9){
  budget=max.level
  goal=ex.setup$optimization_type_value
  goal.seek=1
}else if (ex.setup$optimization_type==10){
  budget=max.level
  goal=ex.multigoal[iter]$goal
  goal.seek=1
  if (is.na(ex.multigoal[iter]$check)) multi.check=max.level else multi.check=ex.multigoal[iter]$check
}

# re-calculate budget for incremental optm
if (ex.setup$optimization_type==5) budget=budget+sum(curve$sp_min[!duplicated(curve[,c("bdgt_id"),with=F])])
if (ex.setup$optimization_type==9) goal=goal+sum(calc_npv(curve$sp_plan))
if (ex.setup$optimization_type==3) budget=sum(curve$sp_plan[!duplicated(curve[,c("bdgt_id"),with=F])])-budget

# check constrinat error
print("Note: Checking Constraint Logic")
check.error=0
error.missingcurve=0
if (nrow(curve)==0){
  check.error=1
  print(paste(print.msg,"Error: There is no response curve under selected dimensions.",sep=""))
  if (print.msg=="cstr") {
    error.missingcurve=1
  }
}else if (sum(curve$sp_min[!duplicated(curve[,c("bdgt_id"),with=F])])>budget&ex.setup$optimization_type!=4){
  check.error=1
  print(paste(print.msg,"Error: Total start spend exceeds total optimization budget.",sep=""))
} else if (sum(curve$sp_min>curve$sp_max) !=0&ex.setup$optimization_type!=4) {
  check.error=1
  print(paste(print.msg,"Error: At least one start spend exceeds its maximum constraint.",sep=""))
} else if ((sum(curve$sp_max[!duplicated(curve[,c("bdgt_id"),with=F])])<budget)&goal.seek==0&ex.setup$optimization_type!=4){
  check.error=1
  print(paste(print.msg,"Error: Total optimization budget exceeds total maximum constraint.",sep=""))
}else{
  # set current spend
  curve$sp_current=curve$sp_min
  
  # check max constrain and flag violated ones
  curve$flag=rep(0,nrow(curve))
  curve$flag[(curve$sp_current+spend_inc)>curve$sp_max]=1
  
  # create some varaibles for optm
  curve$value_current=curve$sp_next=curve$value_next=rep(0,nrow(curve))
  
  #######################################################################################
  # Optimization hill climbing
  #######################################################################################
  print("Note: Optimizing")
  # compute the number of iteration
  sp_initial_sum=sum(curve$sp_min[!duplicated(curve[,c("bdgt_id"),with=F])])
  loop=floor((budget-sp_initial_sum)/spend_inc)
  
  if ((budget-sp_initial_sum)%%spend_inc!=0) {
    sp_inc_last=budget-sp_initial_sum-loop*spend_inc
    loop=loop+1  
  }else{
    sp_inc_last=spend_inc
  }
  
  # compute initial value
  curve$value_current=calc_npv(curve$sp_current)
  
  # goal seek optm initial check
  check.goal.ini=0
  if (ex.setup$optimization_type %in% c(2,9,10)){
    kpi_old=sum(curve$value_current)
    if (kpi_old >=goal) check.goal.ini=1
  }else if(ex.setup$optimization_type==6){
    summary.sp=curve[!duplicated(curve[,c("bdgt_id"),with=F]),]
    if (sum(curve$value_current)==0) kpi_old=0 else
      kpi_old=sum(summary.sp$sp_current)/sum(curve$value_current)
    if (kpi_old >=goal) check.goal.ini=1
  }else if(ex.setup$optimization_type==7){
    summary.sp=curve[!duplicated(curve[,c("bdgt_id"),with=F]),]
    if (sum(curve$value_current)==0) kpi_old=0 else
      kpi_old=sum(curve$value_current)/(sum(summary.sp$sp_current)*(1-tax))-1
    if (kpi_old >=goal) check.goal.ini=1
  }else if(ex.setup$optimization_type==8){
    summary.sp=curve[!duplicated(curve[,c("bdgt_id"),with=F]),]
    if (sum(curve$value_current)==0) kpi_old=0 else
      kpi_old=sum(curve$value_current)-(sum(summary.sp$sp_current)*(1-tax))
  }else{
    kpi_old=0
  }
  
  # optm loop
  if(round(loop/20)==0) int=5 else int=round(loop/20)
  if (loop==0 | ex.setup$optimization_type==4 | check.goal.ini==1) {
    summary.sp=curve[!duplicated(curve[,c("bdgt_id"),with=F]),]
    print("Note: Optimization is completed.")
    if (check.goal.ini==1) print("Note: Optimization reached goal value.")
  }else{
    # create log
    marg=vector("list",1)
    
    # main loop part
    #withProgress(message = '', value = 0, {
    for (i in 1:loop){
      #incProgress(100*i/loop, detail = paste("Optimization: ",round(100*i/loop,digit=0),"% completed. ",sep=""))
      if (i%%int==0) print(paste("Note: Optimization: ",round(100*i/loop,digit=0),"% completed. ",Sys.time(),sep=""))
      
      if (i==loop) {
        sp_inc=sp_inc_last
      } else{
        sp_inc=spend_inc
      }
      
      # compute spend_next
      curve$sp_next[curve$flag==0]=curve$sp_current[curve$flag==0]+sp_inc
      # compute value next
      curve$value_next=calc_npv(curve$sp_next)
      curve$value_next[curve$flag==1]=0
      # compute delta sales
      value_inc=curve$value_next-curve$value_current
      value_inc[curve$flag==1]=0
      value_inc_agg=data.table(bdgt_id=curve$bdgt_id,value_inc)[,list(sum=sum(value_inc)),by=bdgt_id]
      # compute kpi corresponding to optm type and select curve to allocate budget
      if (ex.setup$optimization_type==6){
        summary.sp=curve[!duplicated(curve[,c("bdgt_id"),with=F]),]
        kpi=(sum(summary.sp$sp_current)+sp_inc)/(value_inc_agg$sum+sum(curve$value_current))
        index=value_inc_agg$bdgt_id %in% unique(curve$bdgt_id[curve$flag==1]) 
        kpi[index]=max.level
        index=which.min(kpi)
        if (kpi[index]-kpi_old==0) break
        kpi_old=kpi[index]
      }else if (ex.setup$optimization_type==7){
        summary.sp=curve[!duplicated(curve[,c("bdgt_id"),with=F]),]
        kpi=(value_inc_agg$sum+sum(curve$value_current))/((sum(summary.sp$sp_current)+sp_inc)*(1-tax))-1
        index=value_inc_agg$bdgt_id %in% unique(curve$bdgt_id[curve$flag==1]) 
        kpi[index]=0
        index=which.max(kpi)
        if (kpi[index]-kpi_old==0) break
        kpi_old=kpi[index]
      }else if (ex.setup$optimization_type==8){
        summary.sp=curve[!duplicated(curve[,c("bdgt_id"),with=F]),]
        kpi=(value_inc_agg$sum+sum(curve$value_current))-(sum(summary.sp$sp_current)+sp_inc)*(1-tax)
        index=value_inc_agg$bdgt_id %in% unique(curve$bdgt_id[curve$flag==1]) 
        kpi[index]=0
        index=which.max(kpi)
        if (kpi[index]-kpi_old==0) break
        kpi_old=kpi[index]
      }else {
        index=which.max(value_inc_agg$sum)
        if (value_inc_agg$sum[index]==0) break
      }
      
      bdgt_id=value_inc_agg$bdgt_id[index]
      index.curve=curve$bdgt_id %in% bdgt_id
      
      curve$sp_current[index.curve]=curve$sp_current[index.curve]+sp_inc
      curve$value_current[index.curve]=curve$value_next[index.curve] 
      
      # check max constrain and flag if necessary
      index.check=(curve$sp_current[index.curve]+sp_inc)>curve$sp_max[index.curve]
      curve$flag[index.curve][index.check]=1 
      
      # record marginal
      max.value.inc=value_inc_agg$sum[index]
      marg[[i]]=data.frame(Iteration=i,bdgt_id,Value_inc=max.value.inc,Spend_inc=sp_inc)
      
      # check goal-based optimization
      if (ex.setup$optimization_type %in% c(1,3,5)){
        goal.check=0
      }else if (ex.setup$optimization_type %in% c(2,9,10)){
        goal.check=sum(curve$value_current)
        source("opt_input_multicheck.r",local = T)
        if (sum(curve$value_current)>=goal) break
        if (max.value.inc<value.inc.threshold) break  
      }else if (ex.setup$optimization_type==6){
        goal.check=kpi_old
        if(kpi_old>=goal) break
        if (max.value.inc<(value.inc.threshold)) break  
      }else if (ex.setup$optimization_type==7){
        goal.check=kpi_old
        if (i==1 & kpi_old<goal) break
        if (max.value.inc<value.inc.threshold) break 
        #check next step
        curve1=curve
        if (i==loop) {
          sp_inc=sp_inc_last
        } else{
          sp_inc=spend_inc
        }
        # compute spend and value next
        curve1$sp_next[curve1$flag==0]=curve1$sp_current[curve1$flag==0]+sp_inc
        curve1$value_next=calc_npv(curve1$sp_next)
        curve1$value_next[curve$flag==1]=0
        # compute delta sales
        value_inc=curve1$value_next-curve1$value_current
        value_inc[curve1$flag==1]=0
        # compute next kpi
        value_inc_agg=data.table(bdgt_id=curve1$bdgt_id,value_inc)[,list(sum=sum(value_inc)),by=bdgt_id]
        summary.sp=curve1[!duplicated(curve1[,c("bdgt_id"),with=F]),]
        kpi1=(value_inc_agg$sum+sum(curve1$value_current))/((sum(summary.sp$sp_current)+sp_inc)*(1-tax))-1
        index1=value_inc_agg$bdgt_id %in% unique(curve1$bdgt_id[curve1$flag==1]) 
        kpi1[index1]=0
        if(kpi_old>=goal & max(kpi1)<goal) break
      }else if (ex.setup$optimization_type==8){
        goal.check=kpi_old
        curve1=curve
        if (i==loop) {
          sp_inc=sp_inc_last
        } else{
          sp_inc=spend_inc
        }
        # compute spend and value next
        curve1$sp_next[curve1$flag==0]=curve1$sp_current[curve1$flag==0]+sp_inc
        curve1$value_next=calc_npv(curve1$sp_next)
        curve1$value_next[curve$flag==1]=0
        # compute delta sales
        value_inc=curve1$value_next-curve1$value_current
        value_inc[curve1$flag==1]=0
        # compute next kpi
        value_inc_agg=data.table(bdgt_id=curve1$bdgt_id,value_inc)[,list(sum=sum(value_inc)),by=bdgt_id]
        summary.sp=curve1[!duplicated(curve1[,c("bdgt_id"),with=F]),]
        kpi1=(value_inc_agg$sum+sum(curve1$value_current))-(sum(summary.sp$sp_current)+sp_inc)*(1-tax)
        index1=value_inc_agg$bdgt_id %in% unique(curve1$bdgt_id[curve1$flag==1]) 
        kpi1[index1]=0
        if (max(kpi1)<goal.check) break
      }
      if (i==loop) print("Note: Optimization is completed.")
    } # optm for loop 
    #})#withProgress
      
    # output message
    if((goal.check>=goal)&(ex.setup$optimization_type %in% c(2,6,7,9,10))) {
      print("Note: Optimization reached goal value.")
    }
    
    if ((goal.check<goal)&(ex.setup$optimization_type %in% c(2,6,7,9,10))) print(paste(print.msg,"Warning: Optimization cannot hit goal. ","Goal:",format(round(goal,digits=0),big.mark=",", trim=T,scientific = F)," Actual generated:",format(round(goal.check,digits=0),big.mark=",", trim=T,scientific = F),sep=""))
    if (ex.setup$optimization_type ==10) if (multi.stop==1) print(paste(print.msg,"Warning: Goal seek hit stop criterion.",sep=""))
    
    summary.sp=curve[!duplicated(curve[,c("bdgt_id"),with=F]),]
    bdgt.left=budget-sum(summary.sp$sp_current)
    if (value_inc_agg$sum[index]==0&goal.seek==0){
      if (sum(curve$flag==0)==0) {
        print(paste(print.msg,"Warning: Optimization cannot allocate all budget since all response curves have hit their maximum constraints. ","Budget left:",format(round(bdgt.left,digits=0),big.mark=",", trim=T,scientific = F),sep=""))
      }else{
        print(paste(print.msg,"Warning: Optimization cannot allocate all budget since all response curves have hit their saturation points. ","Budget left:",format(round(bdgt.left,digits=0),big.mark=",", trim=T,scientific = F),sep=""))
      } 
    }
    
    # create final log
    if (!is.null(marg[[1]])){
      marg1=marg[!sapply(marg,is.null)]
      marg1=data.table(do.call("rbind",marg1))
      marg1=marg1[,spend_start:=sum(ex.cstr.final$sp_min)]
      marg1=marg1[,value_start:=sum(calc_npv(curve$sp_min))]
      marg1=marg1[order(marg1$Iteration),]
    }
  }
}# constraint error check