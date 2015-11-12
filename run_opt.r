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
# opt_id=216
# client_id=9
# # DB server info
# db.server="127.0.0.1"
# db.name="nviz"
# port=3306
# username="root"
# password="bitnami"
# .libPaths("/home/rstudio/R/x86_64-pc-linux-gnu-library/3.2")

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
