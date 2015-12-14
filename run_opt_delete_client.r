suppressMessages(suppressWarnings(library(RMySQL)))
# True is to staging DB and F is to production DB
is.staging=T 
# True is to staging DB and F is to production DB
is.staging=T 
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
main.path="d:\\Archives\\Git\\opt-admin\\" # opt files path
client_id=12
client.list=c(
  "opt_input_cps",
  "opt_input_cstr_output",
  "opt_input_curvegroup",
  "opt_input_dim_chan",
  "opt_input_dim_dma",
  "opt_input_dim_salchan",
  "opt_input_dim_sales",
  "opt_input_event_level",
  "opt_input_optimization_targets",
  "opt_input_optimization_types",
  "opt_input_optimization_wins",
  "opt_input_setup",
  "opt_modelinput_bdgt",
  "opt_modelinput_curve",
  "opt_modelinput_hidden_cstr",
  "opt_modelinput_output",
  "opt_modelinput_season",
  "opt_modelinput_clv",
  "opt_modules",
  "opt_modules_dim",
  "opt_modules"
)
opt.list=c(
  "opt_output",
  "opt_output_drilldown",
  "opt_userinput_cps",
  "opt_userinput_cstr",
  "opt_userinput_cstr_output",
  "opt_userinput_curvegroup",
  "opt_userinput_dim_chan",
  "opt_userinput_dim_dma",
  "opt_userinput_dim_salchan",
  "opt_userinput_dim_sales",
  "opt_userinput_event",
  "opt_userinput_multigoal",
  "opt_userinput_setup"
)
save.list=c(
  "opt_cps","opt_cstr","opt_plan"
)

conn <- dbConnect(MySQL(),user=username, password=password,dbname=db.name, host=db.server)
source(paste(main.path,"adm_delete_client.r",sep=""),local=T)
dbDisconnect(conn)