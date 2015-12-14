args <- commandArgs(T)
setwd(args[1])
# main code path
main.path=args[2]
client_id=as.numeric(args[3])
# DB server info
db.server=args[4]
db.name=args[5]
port=as.numeric(args[6])
username=args[7]
password=args[8]
.libPaths(args[9])
user_id=as.numeric(args[10])
type=args[11] # cstr, plan, event or cps
save.name=args[12] # name for save
file.name=args[13] # uploaded file name

# setwd("d:\\Users\\xzhou\\Desktop\\")
# # True is to staging DB and F is to production DB
# is.staging=F 
# # DB server info
# db.server="127.0.0.1"
# db.name="nviz"
# port=3306
# if (is.staging){
#   username="root"
#   password="bitnami"
# }else{
#   username="Zkdz408R6hll"
#   password="XH3RoKdopf12L4BJbqXTtD2yESgwL$fGd(juW)ed"
# }
# client_id=9
# user_id=1
# type="cps" # cstr, plan, event or cps
# save.name="mark_test8" # name for save
# main.path="d:\\Archives\\Git\\opt-admin\\" # opt files path
# file.name="upload_cps.csv"

#########################################################################################
suppressMessages(suppressWarnings(library(RMySQL)))
suppressMessages(suppressWarnings(library(data.table)))
suppressMessages(suppressWarnings(library(jsonlite)))
MySQL(max.con=900)
conn <- dbConnect(MySQL(),user=username, password=password,dbname=db.name, host=db.server)
source(paste(main.path,"adm_upload.r",sep=""),local=T)
dbDisconnect(conn)
