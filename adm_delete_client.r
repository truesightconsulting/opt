

# delete from clients table
dbGetQuery(conn,paste("delete from clients where id=",client_id,sep=""))
# delete tables by client id
for (i in 1:length(client.list)){
  query=paste("delete from ",client.list[i]," where client_id=",client_id,sep="")
  dbGetQuery(conn,query)
}

# delete tables by opt id
opt_id=dbGetQuery(conn,paste("select id from opt_optimizations where client_id=",client_id,sep=""))$id
if (length(opt_id)!=0){
 for (i in 1:length(opt.list)){
    query=paste("delete from ",opt.list[i]," where opt_id in (",paste(opt_id,collapse = ","),")",sep="")
    dbGetQuery(conn,query)
  } 
}
dbGetQuery(conn,paste("delete from opt_optimizations where client_id=",client_id,sep=""))

# delete save tabls
for (i in 1:length(save.list)){
  save_id=dbGetQuery(conn,paste("select id from ",save.list[i]," where client_id=",client_id,sep=""))$id
  if (length(save_id)!=0){
    tb.name=paste(save.list[i],"_save",sep="")
    id.name=paste(strsplit(save.list[i],"opt_")[[1]][2],"_id",sep="")
    query=paste("delete from ",tb.name," where ",id.name," in (",paste(save_id,collapse = ","),")",sep="")
    dbGetQuery(conn,query)
  }
  dbGetQuery(conn,paste("delete from ",save.list[i]," where client_id=",client_id,sep=""))
}

