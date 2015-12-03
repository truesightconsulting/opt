#setwd("d:\\Users\\xzhou\\Desktop\\comcast opt test\\")
print("Note: Optimization Process")
start.time=Sys.time()
suppressMessages(suppressWarnings(library(bit64)))
suppressMessages(suppressWarnings(library(data.table)))
suppressMessages(suppressWarnings(library(reshape2)))
suppressMessages(suppressWarnings(library(stringr)))
suppressMessages(suppressWarnings(library(jsonlite)))
# Load in data
source("opt_input_load.r",local = T)

# load functions
source(paste(path,"opt_modelinput_functions.r",sep=""),local = T)

# check multi-goal seek
if (ex.setup$optimization_type==10) {
  n=nrow(ex.multigoal)
  marg.list=vector("list",n)
}else n=1

sp.multi=vector("list",n)
for (iter in 1:n){
  print(paste("Note: Optimization Round",iter))
  
  # reload in data
  if (iter>1) source("opt_input_load.r",local = T)
  
  # generate relevant dim input tables for certain type of optm
  source("opt_input_force_flag.r",local = T)
  
  # generate curve and cps table for time-variant optm
  source(paste(path,"opt_modelinput_gen_tables.r",sep=""),local = T)
  
  # time window error check
  if (ex.setup$optimization_time!=1) check.event.date=0
  
  # prepare curve parameters for optm
  source("opt_input_curve_par.r",local = T)
  
  # flag all the selected curves
  source("opt_input_flag_table.r",local = T)
  
  # update min spend from previous iteration for multi-goal seek
  if (iter>1) source(paste(path,"opt_modelinput_update_minsp.r",sep=""),local = T)
  
  # calc final min and max constraints, them merge them with curve, as well as cps
  source(paste(path,"opt_modelinput_calc_cstr.r",sep=""),local = T)
  
  # optmization
  source(paste(path,"opt_modelinput_optm.r",sep=""),local = T)
  
  # re-generate min spend for multi-goal seek
  if (ex.setup$optimization_type==10) source(paste(path,"opt_modelinput_gen_minsp.r",sep=""),local = T)
}

# output
source("opt_input_post_calc.r",local = T)

#save.image("opt_output.Rdata")
end=Sys.time()-start.time
print(paste("Note: Run time: ",round(end[[1]],digit=2),attr(end,"units"),sep="")) 





