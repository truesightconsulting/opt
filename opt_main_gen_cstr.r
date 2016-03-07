#setwd("d:\\Archives\\R Code\\OPTM\\new constrant\\optm fios\\")
print("Note: Generating Constraints")
start.time=Sys.time()

cstr.name=c("sp_min","sp_max","sp_plan")
cutoff.cl=4 # if no. of row is more then this number, then build that number of clusters

# Load in data
source("opt_input_load.r",local = T)

# load functions
source(paste(path,"opt_modelinput_functions.r",sep=""),local = T)

# some cstr check  
# if (nrow(ex.cstr.input)!=0 & ex.setup$optimization_time==1){
#   # manipulate optm date
#   source(paste(path,("opt_modelinput_gen_optmdate.r"),sep=""),local = T)
#   # check constaint time window
#   if (ex.setup$optimization_time==1) {
#     start.cstr=as.Date(ex.cstr.input$date_start)
#     end.cstr=as.Date(ex.cstr.input$date_end)
#     if ((sum(start.cstr<start.optm)+sum(end.cstr>end.optm))!=0) {
#       cstr.check=1
#       stop("Error: At least one constraint time window falls ouside optimzation time window.")
#     }
#   }# constraint time window check
# }
if (nrow(ex.cstr.input)!=0){
  dim.cstr=dbGetQuery(conn,paste("select dim as dim from opt_modules_dim where flag_cstr=1 and client_id=",client_id))$dim
  dim.cstr=paste(dim.cstr,"_id",sep="")
  cstr.check.tb=ex.cstr.input[,dim.cstr,with=F]
  if (sum(duplicated(cstr.check.tb))!=0){
    print("Error: There is dimension duplication in your constraint/plan/event setup. Please check.")
  }else{
    comma.check=list("vector",ncol(cstr.check.tb))
    for (i in 1:ncol(cstr.check.tb)){
      comma.check[[i]]=grepl(",",cstr.check.tb[[i]])
    }
    cstr.index=apply(do.call("cbind",comma.check),1,sum)
    if (sum(cstr.index)==0) allone.check=T else allone.check=F
    
    if (allone.check & ex.setup$optimization_time==2){
      temp.cstr.output=ex.cstr.input[,c("sp_min","sp_max","sp_plan","opt_id",dim.cstr),with=F]
      for (k in which(sapply(temp.cstr.output,is.character))) set(temp.cstr.output, j=k, value=as.integer(temp.cstr.output[[k]]))
      temp.cstr.output=merge(ex.cstr[,c("client_id","bdgt_id",dim.cstr),with=F],temp.cstr.output,by=dim.cstr,all.y=T)[,!"client_id",with=F]
      if (db.usage){
        dbGetQuery(conn,paste("delete from opt_userinput_cstr_output where opt_id=",opt_id,sep=""))
        dbWriteTable(conn,"opt_userinput_cstr_output",temp.cstr.output,append=T,row.names = F,header=F)
      } else
        write.csv(temp.cstr.output,"opt_input_cstr_output.csv",row.names=F,na="")
    }else if (allone.check==F & ex.setup$optimization_time==2){
      # all one part
      temp.cstr.output=ex.cstr.input[cstr.index==0,c("sp_min","sp_max","sp_plan","opt_id",dim.cstr),with=F]
      for (k in which(sapply(temp.cstr.output,is.character))) set(temp.cstr.output, j=k, value=as.integer(temp.cstr.output[[k]]))
      temp.cstr.output=merge(ex.cstr[,c("client_id","bdgt_id",dim.cstr),with=F],temp.cstr.output,by=dim.cstr) # merge only take overlap part to filter out missing curve
      # not all one part
      source(paste(main.path,"opt_modelinput_gen_cstr.r",sep=""),local=T)
      result=vector("list",3)
      names(result)= c("sp_min","sp_max","sp_plan")
      for (i in c("sp_min","sp_max","sp_plan")){
        temp.output=Reduce(function(...) merge(...,all=TRUE,by="bdgt_id"),Filter(Negate(is.null),
                            list(ex.cstr[,c("bdgt_id",i),with=F],
                                 temp.cstr.output[,c("bdgt_id",i),with=F])))
        if (i=="sp_max"){
          temp.output[is.na(temp.output)]=max.level
          result[[i]]=data.table(bdgt_id=temp.output[[1]],sp_max=do.call(pmin, temp.output[,-1,with=F])) 
        }else if (i=="sp_min"){
          temp.output[is.na(temp.output)]=0
          result[[i]]=data.table(bdgt_id=temp.output[[1]],sp_min=do.call(pmax, temp.output[,-1,with=F])) 
        }else if (i=="sp_plan"){
          temp.output[is.na(temp.output)]=0
          result[[i]]=data.table(bdgt_id=temp.output[[1]],sp_plan=do.call(pmax, temp.output[,-1,with=F]))
        }
      }
      result.all=Reduce(function(...) merge(...,all=TRUE,by="bdgt_id"), result)
      result.all$sp_min[is.na(result.all$sp_min)]=0
      result.all$sp_max[is.na(result.all$sp_max)]=max.level
      result.all$sp_plan[is.na(result.all$sp_plan)]=0
      
      ex.cstr=data.table(dbGetQuery(conn,paste("select * from opt_input_cstr_output where client_id=",client_id,sep="")))
      ex.cstr=merge(ex.cstr[,!names(result.all)[-1],with=F],result.all,by="bdgt_id",all.y=T)
      ex.cstr=data.table(opt_id=rep(opt_id,nrow(ex.cstr)),ex.cstr)
      
      if (db.usage){
        dbGetQuery(conn,paste("delete from opt_userinput_cstr_output where opt_id=",opt_id,sep=""))
        dbWriteTable(conn,"opt_userinput_cstr_output",ex.cstr[,!c("client_id","id"),with=F],append=T,row.names = F,header=F)
      } else
        write.csv(ex.cstr,"opt_input_cstr_output.csv",row.names=F,na="")
      
    }else if (ex.setup$optimization_time==1){
      source(paste(main.path,"opt_modelinput_gen_cstr.r",sep=""),local=T)
      if (db.usage){
        dbGetQuery(conn,paste("delete from opt_userinput_cstr_output where opt_id=",opt_id,sep=""))
        dbWriteTable(conn,"opt_userinput_cstr_output",ex.cstr[,!c("client_id","id"),with=F],append=T,row.names = F,header=F)
      } else
        write.csv(ex.cstr,"opt_input_cstr_output.csv",row.names=F,na="")
    }
    
  }#duplication check
}


end=Sys.time()-start.time
print(paste("Note: Run time: ",round(end[[1]],digit=2),attr(end,"units"),sep="")) 