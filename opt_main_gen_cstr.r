#setwd("d:\\Archives\\R Code\\OPTM\\new constrant\\optm fios\\")
print("Note: Generating Constraints")
start.time=Sys.time()
suppressMessages(suppressWarnings(library(bit64)))
suppressMessages(suppressWarnings(library(data.table)))
suppressMessages(suppressWarnings(library(doSNOW)))

cstr.name=c("sp_min","sp_max","sp_plan")
cutoff.cl=4 # if no. of row is more then this number, then build that number of clusters

# Load in data
source("opt_input_load.r",local = T)

# load functions
source(paste(path,"opt_modelinput_functions.r",sep=""),local = T)

# check cstr time window  
cstr.check=0
if (nrow(ex.cstr.input)!=0 & ex.setup$optimization_time==1){
  # manipulate optm date
  source(paste(path,("opt_modelinput_gen_optmdate.r"),sep=""),local = T)
#   # check constaint time window
#   if (ex.setup$optimization_time==1) {
#     start.cstr=as.Date(ex.cstr.input$date_start)
#     end.cstr=as.Date(ex.cstr.input$date_end)
#     if ((sum(start.cstr<start.optm)+sum(end.cstr>end.optm))!=0) {
#       cstr.check=1
#       stop("Error: At least one constraint time window falls ouside optimzation time window.")
#     }
#   }# constraint time window check
}


if (cstr.check==0 & nrow(ex.cstr.input)!=0 ){
  # check which constraint need to be calc'ed
  if (sum(!is.na(ex.cstr.input$sp_min))!=0) index1=T else index1=F
  if (sum(!is.na(ex.cstr.input$sp_max))!=0) index2=T else index2=F
  if (sum(!is.na(ex.cstr.input$sp_plan))!=0) index3=T else index3=F
  index=c(index1,index2,index3)
  # gen list to save result
  n=sum(index)
  result=vector("list",n)
  names(result)=cstr.name[index]
  
  # constraint gen loop
  for (loop.cstr in 1:n){
    # Load in data
    source("opt_input_load.r",local = T)
    
    # generate setup input tables for constraint
    source(paste(path,"opt_modelinput_check_cstr.r",sep=""),local = T)
    
    print("Note: Building Clusters")
    if (nrow.check==1){
      # calc no. of cluster
#       if (nrow(temp.cstr.input)>cutoff.cl) no.cl=cutoff.cl else no.cl=1
#       cl=makeCluster(no.cl,type="SOCK",outfile="")
#       clusterExport(cl,c("temp.cstr.input"))
#       registerDoSNOW(cl)

      #loop for each row of constraint
      print("Note: Calulating Constraint Allocation")
      result[[names(result)[loop.cstr]]]=
        foreach(iter=1:nrow(temp.cstr.input), .multicombine=T,
                .packages=c("data.table","bit64"),.verbose=F) %do%
        {
          print(paste("Note: ",names(result)[loop.cstr]," ",iter," ",Sys.time(),sep=""))
          
          # load function
          source(paste(path,"opt_modelinput_functions.r",sep=""),local=T)
          
          # Load in data
          source("opt_input_load.r",local=T)
          
          # optm par setup based on constraint 
          source("opt_input_cstr_setup.r",local=T)
          
          # generate curve and cps tables for time-variant version 
          source(paste(path,"opt_modelinput_gen_tables.r",sep=""),local=T)
          
          # prepare curve parameters for optm
          source("opt_input_curve_par.r",local=T)
          
          # flag all the selected curves
          source("opt_input_flag_table.r",local=T)
          
          # calc final min and max constraints, them merge them with curve, as well as cps
          source(paste(path,"opt_modelinput_calc_cstr.r",sep=""),local=T)
          
          # optmization
          source(paste(path,"opt_modelinput_optm.r",sep=""),local=T)
          
          # save result
          temp.output=summary.sp[,c("bdgt_id","sp_current"),with=F]
          setnames(temp.output,"sp_current",paste("sp_current_",iter,sep=""))
          temp.output
        }# loop of each row of constaint
      
      # stopCluster(cl)
      
      print("Note: Transforming Result")
      # merge results and generate final constraint table
      temp.output=Reduce(function(...) merge(...,all=TRUE,by="bdgt_id"), result[[names(result)[loop.cstr]]])
      
      if (names(result)[loop.cstr]=="sp_min"){
        temp.output[is.na(temp.output)]=0
        result[[names(result)[loop.cstr]]]=data.table(bdgt_id=temp.output[[1]],sp_min=do.call(pmax, temp.output[,-1,with=F]))
      }else if (names(result)[loop.cstr]=="sp_max"){
        temp.output[is.na(temp.output)]=max.level
        #temp.output[temp.output==0]=max.level
        result[[names(result)[loop.cstr]]]=data.table(bdgt_id=temp.output[[1]],sp_max=do.call(pmin, temp.output[,-1,with=F]))
      }else if (names(result)[loop.cstr]=="sp_plan"){
        temp.output[is.na(temp.output)]=0
        result[[names(result)[loop.cstr]]]=data.table(bdgt_id=temp.output[[1]],sp_plan=do.call(pmax, temp.output[,-1,with=F]))
      }
    }# nrow.check
  }# loop of min/max/plan
  
  print("Note: Exporting Result")
  # Load in data
  source("opt_input_load.r",local = T)
  
  # calc final min and max for optm with plan
  result.all=Reduce(function(...) merge(...,all=TRUE,by="bdgt_id"), result)
  if ("sp_min" %in% names(result.all)) result.all$sp_min[is.na(result.all$sp_min)]=0
  if ("sp_max" %in% names(result.all)) result.all$sp_max[is.na(result.all$sp_max)]=max.level
  if ("sp_plan" %in% names(result.all)) result.all$sp_plan[is.na(result.all$sp_plan)]=0
  if (ex.setup$optimization_type %in% c(5,9)){
    if ("sp_min" %in% names(result.all)) result.all=result.all[,sp_min:=sp_min+sp_plan] else
      result.all=result.all[,sp_min:=sp_plan]
    if ("sp_max" %in% names(result.all)) result.all=result.all[,sp_max:=sp_max+sp_plan]
  }
  
  # update result to ex.cstr
  ex.cstr=merge(ex.cstr[,!names(result.all)[-1],with=F],result.all,by="bdgt_id",all=T)
  ex.cstr=data.table(opt_id=rep(opt_id,nrow(ex.cstr)),ex.cstr)
  if (db.usage){
    dbGetQuery(conn,paste("delete from opt_userinput_cstr_output where opt_id=",opt_id,sep=""))
    dbWriteTable(conn,"opt_userinput_cstr_output",ex.cstr[,!c("client_id","id"),with=F],append=T,row.names = F,header=F)
  } else
    write.csv(ex.cstr,"opt_input_cstr_output.csv",row.names=F,na="")
} # cstr.check 



end=Sys.time()-start.time
print(paste("Note: Run time: ",round(end[[1]],digit=2),attr(end,"units"),sep="")) 