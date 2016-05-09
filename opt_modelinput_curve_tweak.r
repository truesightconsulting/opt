# prepare curve parameters for optm
print("Note: Calculating Curve Parameters")

# merge clv table
ex.clv$approval[is.na(ex.clv$approval)]=1
temp_dim=get_dim_n("sales")
curve=merge(curve,ex.clv[,c(temp_dim,"clv","approval"),with=F],by=temp_dim,all.x=T)

# tweak a based on approval
curve$a=curve$a*curve$approval

# tweak curve based on time window
curve_f=get_curve_f()
if (dbGetQuery(conn,paste("select status from opt_modules where module='opt_input_date_range' and client_id=",client_id,sep=""))$status==1){
  start.optm=as.Date(ex.setup$date_start)
  end.optm=as.Date(ex.setup$date_end)
  date.temp=optm.date(ex.setup$date_start,ex.setup$date_end)
  n=length(date.temp$range.wk)
  ex.setup$input_increment=n*ex.setup$input_increment
  
  curve[[beta]]=n*curve[[beta]]
  if (curve_f=="ninah") {
    curve$wks=n*curve$wks
  }else if (curve_f %in% c("exp","exp000")){
    curve$b=curve$b/n
  }
}

# formula
if (curve_f=="ninah") {
  # decomp function
  calc_decomp=function(x){
    # x is spend; output is sales
    ad=function(x1,x2){(1 - ((1 - x1 * exp(1) ^ (log(0.5) / curve$hl)) / (exp(1) ^ ((x2/curve$cps) / 
                                                                                      (curve$wks * curve$max) * (-log(1 - curve$hrf)) * 10))))}
    curve$beta.decomp*ad(x1=ad(x1=rep(0,length(curve$wks)),x2=x),x2=x)
  }
  # npv function
  calc_npv=function(x){
    # x is spend; output is sales
    ad=function(x1,x2){(1 - ((1 - x1 * exp(1) ^ (log(0.5) / curve$hl)) / (exp(1) ^ ((x2/curve$cps) / 
                                                                                      (curve$wks * curve$max) * (-log(1 - curve$hrf)) * 10))))}
    curve$beta*ad(x1=ad(x1=rep(0,length(curve$wks)),x2=x),x2=x)
  }
}else if (curve_f=="exp"){
  # decomp function
  calc_decomp=function(x){
    # x is spend; output is sales
    curve$a.decomp*(1-exp(-curve$b*x/curve$cps))
  }
  # npv function
  calc_npv=function(x){
    # x is spend; output is sales
    curve$a*(1-exp(-curve$b*x/curve$cps))
  }
}else if (curve_f=="exp000"){
  # decomp function
  calc_decomp=function(x){
    # x is spend; output is sales
    curve$a.decomp*(1-exp(-curve$b*x/(curve$cps*1000)))
  }
  # npv function
  calc_npv=function(x){
    # x is spend; output is sales
    curve$a*(1-exp(-curve$b*x/(curve$cps*1000)))
  }
}

source("opt_input_curve_par.r",local=T)

# backup curve table
curve.org=curve