# merge clv table
ex.clv$approval[is.na(ex.clv$approval)]=1
temp_dim=get_dim_n("sales")
curve=merge(curve,ex.clv[,c(temp_dim,"clv","approval"),with=F],by=temp_dim,all.x=T)

# tweak a based on approval
curve$a=curve$a*curve$approval