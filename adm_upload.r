
if (type %in% c("cstr","plan")){
  data=fread(file.name,na.strings = "")
  # check
  save.table=dbGetQuery(conn,paste("select * from opt_",type," where client_id=",client_id,sep=""))
  save.col=dbGetQuery(conn,paste("show columns from opt_",type,"_save",sep=""))$Field
  if(sum(!names(data) %in% save.col)!=0){
    print("Error: There is invalid column name. Please check your file")
  }else if (save.name %in% save.table$name){
    print("Error: The name already exists. Please select another name.")
  }else{
    # check values
    options(warn = -1)
    is.time=dbGetQuery(conn,paste("select optimization_time from opt_input_setup where client_id=",client_id,sep=""))$optimization_time
    inc=dbGetQuery(conn,paste("select input_increment from opt_input_setup where client_id=",client_id,sep=""))$input_increment
    options(warn = 0)
    check.value=0
    # spend value check
    if (type=="cstr"){
      sp_min=data$sp_min
      sp_max=data$sp_max
      if (sum(is.na(sp_min)&is.na(sp_max))!=0){
        print("Error: sp_max and sp_min cannot be both missing. Please check your file.")
        check.value=1
      }
      sp_min[is.na(sp_min)]=inc
      sp_max[is.na(sp_max)]=1e+10
      sp_max[sp_max==0]=inc
      if (sum(sp_min<inc | sp_max<inc)!=0) {
        print(paste("Error: sp_min or sp_max cannot be less than ",format(inc,big.mark = ",",scientific=F),sep=""))
        check.value=1
      }
      if (sum(sp_min>sp_max)!=0){
        print("Error: sp_max must greater than or equal to sp_min. Please check your file.")
        check.value=1
      }
    }else if (type=="plan"){
      sp_plan=data$sp_plan
      if (sum(is.na(sp_plan))!=0){
        print("Error: Missing values are not allowed in sp_plan column. Please check your file.")
        check.value=1
      }
      sp_plan[is.na(sp_plan)]=inc
      if (sum(sp_plan<inc)!=0) {
        print(paste("Error: Planned spend cannot be less than ",format(inc,big.mark = ",",scientific=F),sep=""))
        check.value=1
      }
    }
    # time window check
    if (is.time==1){
      data$date_start=as.Date(data$date_start,"%m/%d/%Y")
      data$date_end=as.Date(data$date_end,"%m/%d/%Y")
      date.range=(data$date_end-data$date_start)
      if (!(sum(is.na(data$date_start))==0 & sum(is.na(data$date_end))==0)){
        check.value=1
        print("Error: Missing values are not allowed in date_start and date_end columns. Please check your file.")
      }else if (sum(date.range<7 | date.range>366)!=0){
          check.value=1
          print("Error: Date range must be in between 7 - 366 days.")
      }
    }
    # id column missing value check
    index=grepl("_id",names(data))
    if(sum(is.na(data[,names(data)[index],with=F]))!=0){
      check.value=1
      print("Error: Missing values are not allowed in media channel related columns. Please check your file.")
    }

    if (check.value==0){
      # convert label to id
      dim=names(data)[grepl("_id",names(data))]
      for (i in 1:length(dim)){
        temp.dim=dim[i]
        match=dbGetQuery(conn,paste("select * from opt_label_",strsplit(temp.dim,"_id")[[1]],sep=""))
        for (j in 1:nrow(data)){
          temp.name=unlist(strsplit(data[[temp.dim]][j],","))
          data[[temp.dim]][j]=paste(merge(data.table(label=temp.name),match,by="label")$id,collapse = ",")
        }
      }
      # create name id
      dbWriteTable(conn,paste("opt_",type,sep=""),data.table(client_id=client_id,user_id=user_id,name=save.name,
                                                             created=format(Sys.time(),"%Y-%m-%d %T")),append=T,row.names = F,header=F)
      id=dbGetQuery(conn,paste("select id from opt_",type," where name='",save.name,"' and client_id=",client_id,sep=""))$id
      # upload
      if (type=="cstr"){
        temp=data.table(cstr_id=id,data)
      }else if (type=="plan"){
        temp=data.table(plan_id=id,data)
      }
      dbWriteTable(conn,paste("opt_",type,"_save",sep=""),temp,append=T,row.names = F,header=F)
      print("Success")
      cat(paste("\"Return\":{\"id\":",id,"}\n",sep=""))
    }
  }
}else if (type=="event"){
  data=fread(file.name,na.strings = "")
  # check
  check.value=0
  save.table=dbGetQuery(conn,paste("select * from opt_",type," where client_id=",client_id,sep=""))
  save.col=dbGetQuery(conn,paste("show columns from opt_",type,"_save",sep=""))$Field
  is.time=dbGetQuery(conn,paste("select optimization_time from opt_input_setup where client_id=",client_id,sep=""))$optimization_time
  if(sum(!names(data) %in% save.col)!=0){
    check.value=1
    print("Error: There is invalid column name. Please check your file")
  }else if (save.name %in% save.table$name){
    check.value=1
    print("Error: The name already exists. Please select another name.")
  }else if (sum(is.na(data))!=0){
    check.value=1
    print("Error:  Missing values are not allowed. Please check your file.")
  }else if (is.time==1){
    data$date_start=as.Date(data$date_start,"%m/%d/%Y")
    data$date_end=as.Date(data$date_end,"%m/%d/%Y")
    date.range=(data$date_end-data$date_start)
    if (!(sum(is.na(data$date_start))==0 & sum(is.na(data$date_end))==0)){
      check.value=1
      print("Error: Missing values are not allowed in date_start and date_end columns. Please check your file.")
    }else if (sum(date.range<7 | date.range>366)!=0){
      check.value=1
      print("Error: Date range must be in between 7 - 366 days.")
    }
  }
  if (check.value==0){
    # convert label to id
    dim=names(data)[grepl("_id",names(data))]
    for (i in 1:length(dim)){
      temp.dim=dim[i]
      match=dbGetQuery(conn,paste("select * from opt_label_",strsplit(temp.dim,"_id")[[1]],sep=""))
      for (j in 1:nrow(data)){
        temp.name=unlist(strsplit(data[[temp.dim]][j],","))
        data[[temp.dim]][j]=paste(merge(data.table(label=temp.name),match,by="label")$id,collapse = ",")
      }
    }
    # convert level to value
    match.level=dbGetQuery(conn,paste("select label,value from opt_input_event_level a left join opt_label_event_level b on a.event_level_id=b.id where client_id=",client_id,sep=""))
    setnames(data,"level","label")
    data=merge(data,match.level,by="label",all.x=T)[,!"label",with=F]
    setnames(data,"value","level")
    # convert label to id
    dim=names(data)[grepl("_id",names(data))]
    for (i in 1:length(dim)){
      temp.dim=dim[i]
      match=dbGetQuery(conn,paste("select * from opt_label_",strsplit(temp.dim,"_id")[[1]],sep=""))
      for (j in 1:nrow(data)){
        temp.name=unlist(strsplit(data[[temp.dim]][j],","))
        data[[temp.dim]][j]=paste(merge(data.table(label=temp.name),match,by="label")$id,collapse = ",")
      }
    }
    # convert date format
    if (is.time==1){
      data$date_start=as.Date(data$date_start,"%m/%d/%Y")
      data$date_end=as.Date(data$date_end,"%m/%d/%Y")
    }
    # create name id
    dbWriteTable(conn,paste("opt_",type,sep=""),data.table(client_id=client_id,user_id=user_id,name=save.name,
                                                           created=format(Sys.time(),"%Y-%m-%d %T")),append=T,row.names = F,header=F)
    id=dbGetQuery(conn,paste("select id from opt_",type," where name='",save.name,"' and client_id=",client_id,sep=""))$id
    # upload
    temp=data.table(event_id=id,data)
    dbWriteTable(conn,paste("opt_",type,"_save",sep=""),temp,append=T,row.names = F,header=F)
    print("Success")
    cat(paste("\"Return\":{\"id\":",id,"}\n",sep=""))
  }
}else if (type=="cps"){
  data=fread(file.name,na.strings = "")
  # check
  save.table=dbGetQuery(conn,paste("select * from opt_",type," where client_id=",client_id,sep=""))
  save.col=dbGetQuery(conn,paste("show columns from opt_",type,"_save",sep=""))$Field
  temp.col=names(data)
  temp.col=temp.col[!grepl("_name",temp.col)]

  if(sum(!temp.col %in% save.col)!=0){
    print("Error: There is invalid column name. Please check your file")
  }else if (save.name %in% save.table$name){
    print("Error: The name already exists. Please select another name.")
  }else if (sum(is.na(data))!=0){
    print("Error: Missing value is not allowed. Please check your file")
  }else if (sum(data$cps<=0)!=0){
    print("Error: CPS values must be positive number. Please check your file")
  }else{
    # convert label to id
    dim=names(data)[grepl("_name",names(data))]
    data=data[,!dim,with=F]
    # create name id
    dbWriteTable(conn,paste("opt_",type,sep=""),data.table(client_id=client_id,user_id=user_id,name=save.name,
                                                           created=format(Sys.time(),"%Y-%m-%d %T")),append=T,row.names = F,header=F)
    id=dbGetQuery(conn,paste("select id from opt_",type," where name='",save.name,"' and client_id=",client_id,sep=""))$id
    # upload
    temp=data.table(cps_id=id,data)
    dbWriteTable(conn,paste("opt_",type,"_save",sep=""),temp,append=T,row.names = F,header=F)
    print("Success")
    output.temp=data.table(id=id)
    cat(paste("\"Return\":{\"id\":",id,"}\n",sep=""))
  }
}


