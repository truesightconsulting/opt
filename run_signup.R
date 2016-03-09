suppressMessages(suppressWarnings(library(RMySQL)))
suppressMessages(suppressWarnings(library(data.table)))
suppressMessages(suppressWarnings(library(bcrypt)))
data=fread("c:\\Users\\XinZhou\\Desktop\\new_user.csv",colClasses=c("chr","chr","int"))
pwd="Passw0rd#1"
# True is to staging DB and F is to production DB
is.staging=F 
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
#main.path="d:\\Archives\\Git\\opt-admin\\" # opt files path
#################################################################################################
gensalt(log_rounds = 12)
pwd1=hashpw(pwd, salt = gensalt())
MySQL(max.con=900)
conn <- dbConnect(MySQL(),user=username, password=password,dbname=db.name, host=db.server)
email.list=dbGetQuery(conn,paste("select email from users"))$email
if (sum((data$email %in% email.list))!=0) {
  print("Error: At least one email exists in DB.")
}else {
  for(i in 1:nrow(data)){
    email=data$email[i]
    print(paste("Note: Creating email: ",email,sep=""))
    name=strsplit(email,"@")[[1]][1]
    password=pwd1
    status=1
    confirmed=1
#     created_at=format(Sys.time(),"%Y-%m-%d %H:%M:%S")
#     updated_at=format(Sys.time(),"%Y-%m-%d %H:%M:%S")
    temp=data.table(email=email,name=name,status=status,confirmed=confirmed,password=password)
    dbWriteTable(conn,"users",temp,append=T,row.names = F,header=F)
    
    options(warn = -1)
    user_id=dbGetQuery(conn,paste("select id from users where email='",email,"'",sep=""))$id[1]
    options(warn = 0)
    dbGetQuery(conn,paste("update users set created_at=now() where id=",user_id,sep=""))
    dbGetQuery(conn,paste("update users set updated_at=now() where id=",user_id,sep=""))
    client_id=strsplit(data$client[i],",")[[1]]
    temp=data.table(user_id=rep(user_id,length(client_id)),client_id=client_id)
    dbWriteTable(conn,"assigned_clients",temp,append=T,row.names = F,header=F)
    
    role_id=data$role[i]
    temp=data.table(user_id=user_id,role_id=role_id)
    dbWriteTable(conn,"assigned_roles",temp,append=T,row.names = F,header=F)
  }
}
