lmepack.batch.imputed <- function(phenfile,genfile,pedfile,phen,kinmat,covars=NULL,outfile,col.names=T,sep.ped=",",sep.phe=",",sep.gen=","){
###########################################################
  #library(coxme)
  #check the existence of kinship matrix
  kmat <- NULL; rm(kmat)
  trykin<-try(load(kinmat))
  if (inherits(trykin,"try-error"))
        stop(paste('kinship matrix does not exist at ',kinmat))

  cor.snp <- function(y,x){  
   if(!is.numeric(y))y<-as.numeric(as.factor(y)) 
   return(sd(y)==0 || abs(cor(y,x,use="complete"))>0.99999999 )} 

  read.in.data <- function(phenfile,genfile,pedfile,sep.ped=sep.ped,sep.phe=sep.phe,sep.gen=sep.gen) {
  print("Reading in Data")
  ped.dat <- read.table(genfile,header=TRUE,na.strings="",sep=sep.gen)
  snp.names <- names(ped.dat)[-1]
  pedigree <- read.table(pedfile,header=TRUE,sep=sep.ped)
  gntp.all <- merge(pedigree,ped.dat,by="id")

#read in phenotype data
  phen.dat=read.table(phenfile,header=TRUE,sep=sep.phe)
  phen.name=colnames(phen.dat)[-1]
  n.snp=length(names(gntp.all))

  if(length(grep("^sex$",colnames(phen.dat)))==0) {
  phensnp.dat<-merge(gntp.all,phen.dat,by=c("id"))
  } else {
## sex is one of the columns in the phenotype file
  phensnp.dat<-merge(gntp.all,phen.dat,by=c("id","sex"))
  }
  print("Done reading in data")
  return(list(data=phensnp.dat,snps=snp.names,phen.name=phen.name))
}

#####################main programs##########################
  assign("phen",phen,pos=-1,inherits=T)
  phensnp.dat <- read.in.data(phenfile,genfile,pedfile,sep.ped=sep.ped,sep.phe=sep.phe,sep.gen=sep.gen)
  snplist<-phensnp.dat$snps

  if (is.null(covars)) phenlist<-phensnp.dat$phen.name else 
     if (!is.null(covars) & sum(phensnp.dat$phen.name %in% covars)==length(covars)) phenlist<-phensnp.dat$phen.name[!phensnp.dat$phen.name %in% covars] else  
        stop('some covariates are not available')

  test.dat <- phensnp.dat$data
  assign("test.dat", test.dat, pos=-1,inherits=T)

  if (!is.null(covars) & sum(snplist %in% covars)>=1) {
     names(test.dat)[which(names(test.dat) %in% paste(snplist[snplist %in% covars],".x",sep=""))] <- snplist[snplist %in% covars]
     covars[covars %in% snplist] <- paste(covars[covars %in% snplist],".y",sep="")
  }

  if (!is.null(covars)) {
     covars.dat <- na.omit(test.dat[,covars])
     single.cov <- F
     if (length(covars)==1) single.cov <- var(covars.dat)==0 else {
        single.cov <- any(apply(covars.dat,2,var)==0)
        if (single.cov) stop(paste("Single category in covariates!"))
        for (i in covars){
            cov1 <- covars.dat[,i]
            if (!is.numeric(cov1)) cov1 <-as.numeric(as.factor(cov1))
            for (j in covars[covars!=i]){
                cov2 <- covars.dat[,j]
                if (!is.numeric(cov2)) cov2 <-as.numeric(as.factor(cov2))
                if (abs(cor(cov1,cov2))>0.99999999) stop(paste("Highly correlated covariates ",i," and ",j,"!!",sep=""))
            }
        }
     }
  }   
  
  idlab <- "id"
  result <- NULL
  if (is.null(covars)) test1.dat <- na.omit(test.dat[,c(phen,idlab)]) else { 
     test1.dat <- na.omit(test.dat[,c(phen,idlab,covars)])
     xcovar<-as.matrix(test1.dat[,covars])
     assign("xcovar", xcovar, pos=-1,inherits=T) 
  } 
  id <- test1.dat[,idlab]
  n <- length(id)
  assign("test1.dat", test1.dat, pos=-1,inherits=T)
  assign("id",id,pos=-1,inherits=T)               

  if (is.null(covars)) lme.cov.out<-try(lmekin(test1.dat[,phen]~(1|id),varlist=kmat,na.action=na.omit)) else 
     lme.cov.out<-try(lmekin(test1.dat[,phen]~xcovar+(1|id),varlist=kmat,na.action=na.omit))
  if (class(lme.cov.out)!="try-error") v.cov <- (lme.cov.out$sigma)^2*(1+as.numeric(lme.cov.out$vcoef)) else stop('try-error in reduced model!')

  for (i in snplist) {
      assign("i",i,pos=-1,inherits=T)
      if (is.null(covars)) test2.dat <- na.omit(test.dat[,c(i,phen,idlab)]) else { 
         test2.dat <- na.omit(test.dat[,c(i,phen,idlab,covars)])
         x.covar<-as.matrix(test2.dat[,covars])
         assign("x.covar", x.covar, pos=-1,inherits=T)
      } 
      assign("test2.dat", test2.dat, pos=-1,inherits=T)
       
      imaf <- mean(test2.dat[,i])/2
      count <- table(round(test2.dat[,i]))
      gntps <- names(count)
      count1 <- rep(0,3) 
      count1[as.numeric(gntps)+1] <- count
 
      if (!is.null(covars) & length(unique(test2.dat[,i]))==1) colinear <- F else
         if (!is.null(covars) & length(covars)>1 & length(unique(test2.dat[,i]))>1) colinear <- apply(x.covar,2,cor.snp,x=test2.dat[,i]) else 
            if (!is.null(covars) & length(covars)==1 & length(unique(test2.dat[,i]))>1) colinear <- cor.snp(x.covar,test2.dat[,i]) else 
               if (is.null(covars)) colinear <- F 
     
      if (sum(colinear)>0 | length(unique(test2.dat[,i]))==1 | length(count)==1) result<-rbind(result,c(phen,i,n,imaf,rep(NA,4))) else {  
         if (is.null(covars)) lme.out<-try(lmekin(test2.dat[,phen]~test2.dat[,i]+(1|id),varlist=kmat,na.action=na.omit)) else
            lme.out<-try(lmekin(test2.dat[,phen]~test2.dat[,i]+x.covar+(1|id),varlist=kmat,na.action=na.omit))
         if (class(lme.out)!="try-error") {
            chisq<-lme.out$coef$fixed[2]^2/lme.out$var[2,2]
            tmp<-c(max(v.cov-lme.out$sigma^2*(1+as.numeric(lme.out$vcoef)),0)/var(test2.dat[,phen]),lme.out$coef$fixed[2],sqrt(lme.out$var[2,2]),pchisq(chisq,1,lower.tail=F))  
            result <- rbind(result,c(phen,i,n,imaf,tmp))
         } else result<-rbind(result, c(phen,i,n,imaf,rep(NA,4)))
      }
  }    

  colnames(result)<-c("phen","snp","N","AF","h2q","beta","se","pval")  

  write.table(result, outfile, quote=F,row.names=F, col.names=col.names,sep=",",na="",append=T)

}
