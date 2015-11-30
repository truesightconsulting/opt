args <- commandArgs(T)
setwd(args[1])
# main code path
main.path=args[2]
opt_id=as.numeric(args[3])
client_id=as.numeric(args[4])
# DB server info
db.server=args[5]
db.name=args[6]
port=as.numeric(args[7])
username=args[8]
password=args[9]
.libPaths(args[10])



# setwd("/home/rstudio/nviz/chase/")
# # main code path
# main.path="/home/rstudio/nviz/opt/"
# opt_id=248
# client_id=10
# # DB server info
# db.server="bitnami.cluster-chdidqfrg8na.us-east-1.rds.amazonaws.com"
# db.name="nviz"
# port=3306
# username="Zkdz408R6hll"
# password="XH3RoKdopf12L4BJbqXTtD2yESgwL$fGd(juW)ed"


#######################################################################
suppressMessages(suppressWarnings(library(gdata)))
suppressMessages(suppressWarnings(library(RMySQL)))
MySQL(max.con=900)
# setup for opt on DB
db.usage=T
if (db.usage) conn <- dbConnect(MySQL(),user=username, password=password,dbname=db.name, host=db.server)
run.cstr=T
print.msg="cstr"
source(paste(main.path,"opt_main_gen_cstr.r",sep=""),local=T)
if (db.usage) keep(db.usage,conn,opt_id,client_id,main.path,sure = T) else keep(db.usage,main.path,sure=T)
run.cstr=F
print.msg=""
source(paste(main.path,"opt_main.r",sep=""),local=T)

if (db.usage) dbDisconnect(conn)
