# generate event file
print("Note: Generating Event File")
event.name=dbGetQuery(conn,paste("select dim from opt_modules_dim where flag_event=1 and client_id=",client_id,sep=""))$dim
dim.event=paste(event.name,"_id",sep="")
check.event.date=0
if (nrow(ex.event)!=0) {
#   start.event=as.Date(ex.event$date_start)
#   end.event=as.Date(ex.event$date_end)
#   if ((sum(start.event<start.optm)+sum(end.event>end.optm))!=0) {
#     check.event.date=1
#     print("Error: At least one event time window falls ouside optimzation time window.")
#   }else{
    temp.event=vector("list",nrow(ex.event))
    for (j in 1:nrow(ex.event)){
      date.temp=optm.date(ex.event$date_start[j],ex.event$date_end[j])
      range.wk=date.temp$range.wk
      out.wk=date.temp$out.wk
      if (range.wk[1]==range.wk[length(range.wk)] & length(range.wk)!=1) range.wk[length(range.wk)]=-1
      sales_count=ex.event[j,dim.event,with=F]
      cj.list=foreach (k=1:ncol(sales_count),.multicombine = T) %do% {
        as.integer(strsplit(sales_count[[k]],',')[[1]])
      }
      sales_count1=do.call(CJ,cj.list)
      setnames(sales_count1,names(sales_count1),names(sales_count))
      sales_count2=sales_count1[rep(1:nrow(sales_count1),each=length(range.wk))]
      level=rep(ex.event$level[j],nrow(sales_count2))
      temp.event[[j]]=data.table(sales_count2,week_id=rep(range.wk,nrow(sales_count1)),level=level)
      setnames(temp.event[[j]],"level",paste("level",j,sep="_"))
    } 
    temp.output=Reduce(function(...) merge(...,all=TRUE,by=c(dim.event,"week_id")), temp.event)
    temp.output[is.na(temp.output)]=1
    input.event=data.table(temp.output[,c(dim.event,"week_id"),with=F],level=apply(temp.output[,!c(dim.event,"week_id"),with=F],1,prod))
    
    curve=merge(curve,input.event,by=c(dim.event,"week_id"),all.x=T)
    curve$level[is.na(curve$level)]=1
    curve[[beta]]=curve[[beta]]*curve$level
  # }
}




