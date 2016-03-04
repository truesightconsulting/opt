setwd("/home/rstudio/nviz/kohls/admin/opt/admin/")
suppressMessages(suppressWarnings(library(RMySQL)))
suppressMessages(suppressWarnings(library(data.table)))
# True generate db version files, F generates flat file version files
db.usage=T
# True is to staging DB and F is to production DB
is.staging=T 

client_id=27

# DB server info
db.server="127.0.0.1"
db.name="nviz"
port=3306
if (is.staging){
  username="root"
  password="bitnami"
}else{
  username="Zkdz408R6hll"
  password="XH3RoKdopf12L4BJbqXTtD2yESgwL$fGd(juW)ed"
}
main.path="/home/rstudio/nviz/opt/" # opt files path



if (db.usage) conn <- dbConnect(MySQL(),user=username, password=password,dbname=db.name, host=db.server)
hidden=fread("opt_modelinput_hidden_cstr.csv",na.strings="NULL")
dim=names(hidden)[!grepl("_name",names(hidden))]
hidden=hidden[,dim,with=F]
dbGetQuery(conn,paste("delete from opt_modelinput_hidden_cstr where client_id=",client_id,sep=""))
dbWriteTable(conn,"opt_modelinput_hidden_cstr",hidden,append=T,row.names = F,header=F)
if (db.usage) dbDisconnect(conn)
