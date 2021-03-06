## ----echo=FALSE----------------------------------------------------------
set.seed(2)

## ---- eval=FALSE---------------------------------------------------------
#  
#  N = 30
#  data = hhg.example.datagen(N, 'Parabola')
#  X = data[1,]
#  Y = data[2,]
#  plot(X,Y)
#  
#  #Option 1: Perform the ADP combined test
#  #using partitions sizes up to 4. see documentation for other parameters of the combined test
#  #(it is recommended to use mmax >= 4, or the default parameter for large data sets)
#  combined = hhg.univariate.ind.combined.test(X,Y,nr.perm = 200,mmax=4)
#  combined
#  
#  
#  #Option 2: Perform the hhg test:
#  
#  ## Compute distance matrices, on which the HHG test will be based
#  Dx = as.matrix(dist((X), diag = TRUE, upper = TRUE))
#  Dy = as.matrix(dist((Y), diag = TRUE, upper = TRUE))
#  
#  hhg = hhg.test(Dx, Dy, nr.perm = 1000)
#  
#  hhg
#  

## ---- eval=FALSE---------------------------------------------------------
#  
#  N0=50
#  N1=50
#  X = c(c(rnorm(N0/2,-2,0.7),rnorm(N0/2,2,0.7)),c(rnorm(N1/2,-1.5,0.5),rnorm(N1/2,1.5,0.5)))
#  Y = (c(rep(0,N0),rep(1,N1)))
#  #plot the two distributions by group index (0 or 1)
#  plot(Y,X)
#  
#  
#  #Option 1: Perform the Sm combined test
#  
#  
#  combined.test = hhg.univariate.ks.combined.test(X,Y)
#  combined.test
#  
#  
#  #Option 2: Perform the hhg K-sample test:
#  
#  
#  Dx = as.matrix(dist(X, diag = TRUE, upper = TRUE))
#  
#  hhg = hhg.test.k.sample(Dx, Y, nr.perm = 1000)
#  
#  hhg
#  
#  

## ---- eval=FALSE---------------------------------------------------------
#  
#  n=30 #number of samples
#  dimensions_x=5 #dimension of X matrix
#  dimensions_y=5 #dimension of Y matrix
#  X=matrix(rnorm(n*dimensions_x,mean = 0, sd = 1),nrow = n,ncol = dimensions_x) #generate noise
#  Y=matrix(rnorm(n*dimensions_y,mean =0, sd = 3),nrow = n,ncol = dimensions_y)
#  
#  Y[,1] = Y[,1] + X[,1] + 4*(X[,1])^2 #add in the relations
#  Y[,2] = Y[,2] + X[,2] + 4*(X[,2])^2
#  
#  #compute the distance matrix between observations.
#  #User may use other distance metrics.
#  Dx = as.matrix(dist((X)), diag = TRUE, upper = TRUE)
#  Dy = as.matrix(dist((Y)), diag = TRUE, upper = TRUE)
#  
#  #run test
#  hhg = hhg.test(Dx, Dy, nr.perm = 1000)
#  
#  hhg
#  

## ---- eval=FALSE---------------------------------------------------------
#  
#  #multivariate k-sample, with k=3 groups
#  n=100 #number of samples in each group
#  x1 = matrix(rnorm(2*n),ncol = 2) #group 1
#  x2 = matrix(rnorm(2*n),ncol = 2) #group 2
#  x2[,2] = 1*x2[,1] + x2[,2]
#  x3 = matrix(rnorm(2*n),ncol = 2) #group 3
#  x3[,2] = -1*x3[,1] + x3[,2]
#  x= rbind(x1,x2,x3)
#  y=c(rep(0,n),rep(1,n),rep(2,n)) #group numbers, starting from 0 to k-1
#  
#  plot(x[,1],x[,2],col = y+1,xlab = 'first component of X',ylab = 'second component of X',
#       main = 'Multivariate K-Sample Example with K=3 \n Groups Marked by Different Colors')
#  
#  Dx = as.matrix(dist(x, diag = TRUE, upper = TRUE)) #distance matrix
#  
#  hhg = hhg.test.k.sample(Dx, y, nr.perm = 1000)
#  
#  hhg
#  

## ---- eval=FALSE---------------------------------------------------------
#  
#  N = 35
#  data = hhg.example.datagen(N, 'Parabola')
#  X = data[1,]
#  Y = data[2,]
#  plot(X,Y)
#  
#  
#  #I) Computing test statistics , with default parameters:
#  
#  #statistic:
#  hhg.univariate.ADP.Likelihood.result = hhg.univariate.ind.stat(X,Y)
#  hhg.univariate.ADP.Likelihood.result
#  
#  #null table:
#  ADP.null = hhg.univariate.ind.nulltable(N)
#  #pvalue:
#  hhg.univariate.ind.pvalue(hhg.univariate.ADP.Likelihood.result, ADP.null)
#  

## ---- eval=FALSE---------------------------------------------------------
#  
#  #II) Computing test statistics , with summation over Data Derived Partitions (DDP), using Pearson scores, and partition sizes up to 5:
#  
#  #statistic:
#  hhg.univariate.DDP.Pearson.result = hhg.univariate.ind.stat(X,Y,variant = 'DDP',score.type = 'Pearson', mmax = 5)
#  hhg.univariate.DDP.Pearson.result
#  
#  #null table:
#  DDP.null = hhg.univariate.ind.nulltable(N,mmax = 5,variant = 'DDP',score.type = 'Pearson', nr.replicates = 1000)
#  #pvalue , for different partition sizes:
#  hhg.univariate.ind.pvalue(hhg.univariate.DDP.Pearson.result, DDP.null, m =2)
#  hhg.univariate.ind.pvalue(hhg.univariate.DDP.Pearson.result, DDP.null, m =5)
#  

## ---- eval=FALSE---------------------------------------------------------
#  
#  N = 35
#  data = hhg.example.datagen(N, 'Parabola')
#  X = data[1,]
#  Y = data[2,]
#  plot(X,Y)
#  
#  #Perform MinP & Fisher Tests - without existing null tables. Null tables are generated by the test function.
#  #using partitions sizes up to 4. see documentation for other parameters of the combined test (using existing null tables when performing many tests)
#  results = hhg.univariate.ind.combined.test(X,Y,variant='DDP' ,nr.perm = 200,mmax=4)
#  results
#  
#  

## ---- eval=FALSE---------------------------------------------------------
#  #KS example - two groups of size 50
#  N0=50
#  N1=50
#  X = c(c(rnorm(N0/2,-2,0.7),rnorm(N0/2,2,0.7)),c(rnorm(N1/2,-1.5,0.5),rnorm(N1/2,1.5,0.5)))
#  Y = (c(rep(0,N0),rep(1,N1)))
#  #plot distributions of result by group
#  plot(Y,X)
#  
#  
#  statistic = hhg.univariate.ks.stat(X,Y)
#  statistic
#  
#  nulltable = hhg.univariate.ks.nulltable(c(N0,N1))
#  hhg.univariate.ks.pvalue(statistic , nulltable) #pvalue of the default number of partitions
#  
#  hhg.univariate.ks.pvalue(statistic , nulltable,m=5) #pvalue of partition size 5
#  

## ---- eval=FALSE---------------------------------------------------------
#  
#  combined.test = hhg.univariate.ks.combined.test(X,Y,nulltable)
#  combined.test
#  

## ---- eval=FALSE---------------------------------------------------------
#  # download from site http://www.math.tau.ac.il/~ruheller/Software.html
#  
#  #using an already ready null table as object (for use in test functions)
#  #for example, ADP likelihood ratio statistics, for the independence problem, for sample size n=300
#  load('Object-ADP-n_300.Rdata') #=>null.table
#  
#  #or using a matrix of statistics generated for the null distribution, to create your own table.
#  load('ADP-nullsim-n_300.Rdata') #=>mat
#  null.table = hhg.univariate.nulltable.from.mstats(m.stats = mat,minm = 2,maxm = 5,type = 'Independence',
#               variant = 'ADP',size = 300,score.type = 'LikelihoodRatio',aggregation.type = 'sum')
#  

## ---- eval=FALSE---------------------------------------------------------
#  
#  
#  library(parallel)
#  library(doParallel)
#  library(foreach)
#  library(doRNG)
#  
#  #generate an independence null table
#  nr.cores = 4 #this is computer dependent
#  n = 30 #size of independence problem
#  nr.reps.per.core = 25
#  mmax =5
#  score.type = 'LikelihoodRatio'
#  aggregation.type = 'sum'
#  variant = 'ADP'
#  
#  #generating null table of size 4*25
#  
#  #single core worker function
#  generate.null.distribution.statistic =function(){
#    library(HHG)
#    null.table = NULL
#    for(i in 1:nr.reps.per.core){
#      #note that the statistic is distribution free (based on ranks), so creating a null table
#      #(for the null distribution) is essentially permuting over the ranks
#      statistic = hhg.univariate.ind.stat(1:n,sample(1:n),
#                                          variant = variant,
#                                          aggregation.type = aggregation.type,
#                                          score.type = score.type,
#                                          mmax = mmax)$statistic
#      null.table=rbind(null.table, statistic)
#    }
#    rownames(null.table)=NULL
#    return(null.table)
#  }
#  
#  #parallelize over cores
#  cl = makeCluster(nr.cores)
#  registerDoParallel(cl)
#  res = foreach(core = 1:nr.cores, .combine = rbind, .packages = 'HHG',
#                .export=c('variant','aggregation.type','score.type','mmax','nr.reps.per.core','n')) %dorng% {
#                  generate.null.distribution.statistic()
#                }
#  stopCluster(cl)
#  
#  #the null table:
#  head(res)
#  
#  #as object to be used:
#  null.table = hhg.univariate.nulltable.from.mstats(res,minm=2, maxm = mmax,type = 'Independence',
#                                                    variant = variant,size = n,score.type = score.type,
#                                                    aggregation.type = aggregation.type)
#  
#  #using the null table, checking for dependence in a linear relation
#  x=rnorm(n)
#  y=x+rnorm(n)
#  ADP.test = hhg.univariate.ind.combined.test(x,y,null.table)
#  ADP.test #results
#  
#  
#  

## ---- eval=FALSE---------------------------------------------------------
#  
#  library(parallel)
#  library(doParallel)
#  library(foreach)
#  library(doRNG)
#  
#  #generate a k sample null table
#  nr.cores = 4 #this is computer dependent
#  n1 = 25 #size of first group
#  n2 = 25 #size of first group
#  nr.reps.per.core = 25
#  mmax =5
#  score.type = 'LikelihoodRatio'
#  aggregation.type = 'sum'
#  
#  #generating null table of size 4*25
#  
#  #single core worker function
#  generate.null.distribution.statistic =function(){
#    library(HHG)
#    null.table = NULL
#    for(i in 1:nr.reps.per.core){
#      #note that the statistic is distribution free (based on ranks), so creating a null table
#      #(for the null distribution) is essentially permuting over the ranks
#      statistic = hhg.univariate.ks.stat(1:(n1+n2),sample(c(rep(0,n1),rep(1,n2))),
#                                          aggregation.type = aggregation.type,
#                                          score.type = score.type,
#                                          mmax = mmax)$statistic
#      null.table=rbind(null.table, statistic)
#    }
#    rownames(null.table)=NULL
#    return(null.table)
#  }
#  
#  #parallelize over cores
#  cl = makeCluster(nr.cores)
#  registerDoParallel(cl)
#  res = foreach(core = 1:nr.cores, .combine = rbind, .packages = 'HHG',
#                .export=c('n1','n2','aggregation.type','score.type','mmax','nr.reps.per.core')) %dorng% {
#                  generate.null.distribution.statistic()
#                }
#  stopCluster(cl)
#  
#  #the null table:
#  head(res)
#  
#  #as object to be used:
#  null.table = hhg.univariate.nulltable.from.mstats(res,minm=2, maxm = mmax,type = 'KSample',
#                                                    variant = 'KSample-Variant',size = c(n1,n2),score.type = score.type,
#                                                    aggregation.type = aggregation.type)
#  
#  #using the null table, checking for dependence in a case of two distinct samples
#  x=1:(n1+n2)
#  y=c(rep(0,n1),rep(1,n2))
#  Sm.test = hhg.univariate.ks.combined.test(x,y,null.table)
#  Sm.test
#  

