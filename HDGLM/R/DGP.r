#'  Data Generate Process
#'
#'  Generate the covariates and the response for generalized linear models in simulation. 
#'  
#'
#' @param n  the sample size.
#' @param p  the dimension of the covariates.
#' @param alpha  the coefficients in moving average model
#' @param norm the norm of coefficient vector under the alternative hypothesis (norm of \eqn{\beta} or \eqn{\beta^{(2)}}), the default is 0 (the null hypothesis). 
#' @param no the number of nonzero coefficients under the alternative hypothesis (do not account the number of nuisance parameter). The default is  \code{NA}, which means the data are generated under the null hypothesis.   
#' @param betanui  the vector which denotes the value of the nuisance coefficients. The default is  \code{NULL} which means the global test.
#' @param model a character string to describe the model. The default is \code{"gaussian"}, which denotes the linear model.
#'              The other options are \code{"poisson"}, \code{"logistic"}  and \code{"negative_binomial"} models.    
#' @return An object of class "DGP" is a list containing the following components:
#' \item{X}{the design matrix with \eqn{n} rows and \eqn{p} columns,  where \eqn{n} is the sample size and \eqn{p} is the dimension of the covariates.}
#' \item{Y}{the response with length \eqn{n}} 
#' @note  The covariates \eqn{X[i]=(X[i1],X[i2],...,X[ip])} are generated by the moving average model 
#'   \deqn{ X[ij]=\alpha[1]Z[ij]+\alpha[2]Z[i(j+1)]+...+\alpha[T]Z[i(j+T-1)],}
#' where \eqn{Z[i]=(Z[i1],Z[i2],...,Z[i(p+T-1)])} were generated from the \eqn{p+T-1} dimensional standard normal distribution
#' @author Bin Guo
#' @references Guo, B. and Chen, S. X. (2015). Tests for High Dimensional Generalized Linear Models.
#' @seealso \code{\link{HDGLM_test}}
#' @examples
#' alpha=runif(5,min=0,max=1) 
#' ## Example 1: Linear model
#' ## H_0:  \beta_0=0
#' DGP_0=DGP(80,320,alpha) 
#' 

#' ## Example 2: Logistic model
#' ## H_0:  \beta_0=0
#' DGP_0=DGP(80,320,alpha,model="logistic") 
#' 

#' ## Example 3:  Linear model with the first five coefficients to be nonzero, 
#' ## the square of the norm of the coefficients to be 0.2
#' DGP_0=DGP(80,320,alpha,sqrt(0.2),5) 
#'
 

DGP<-function(n,p,alpha,norm=0,no=NA,betanui=NULL,model="gaussian")
{
  if(is.null(betanui))
  {
  if(is.na(no))
  {
  no=1
  }
  
  T=length(alpha)
  X<-matrix(numeric(n*p),nrow=n)
  mu<-numeric(p)
  beta1=(norm/sqrt(no))
  beta<-numeric(p)
  beta[1:no]<-beta1
  y<-numeric(n)
  h<-numeric(n)
  tune<-numeric(n)
  }
  
  if(!is.null(betanui))
  {
  
  if(is.na(no))
  {
  no=1
  }

  T=length(alpha)
  X<-matrix(numeric(n*p),nrow=n)
  mu<-numeric(p)
  beta1=(norm/sqrt(no))
  beta<-numeric(p)
  ID<-c(1:p)
  
  p_1=length(betanui)
  ID_1<-1:p_1   #First we choose p_1 coefficient as nuisance#
  ID_2<-(p_1+1):(p_1+no)

  beta[ID_1]<-betanui   #The coefficients for nuisance 
  beta[ID_2]<-beta1 
  
  y<-numeric(n)
  h<-numeric(n)
  tune<-numeric(n)
  }
  
  for(i in 1:n)
  { 
  Z=rnorm(T+p)
 # dyn.load("/data/binguo/guobin/simulation9.28/generX.dll")
  storage.mode(Z)<-"double"
  storage.mode(alpha)<-"double"
  storage.mode(p)<-"integer"
  storage.mode(T)<-"integer"
  X[i,]<-.Fortran("generX",Z,alpha,mu,p,T,res=numeric(p))$res  
  }

    
  if(model=="gaussian")
  {
     for(i in 1:n)
     {
     tune[i]=X[i,]%*%beta
     if (abs(tune[i])>1000)
     {
     t=floor(abs(tune[i])/1000)+1
     X[i,]=X[i,]/t
     tune[i]=tune[i]/t     
     }
   y[i]<-tune[i]+rnorm(1)
     }
  
 }
    if(model=="poisson")
    {
     for(i in 1:n)
     {
      tune[i]=X[i,]%*%beta
      if(tune[i]<0)
      {
      X[i,]=-X[i,]
      tune[i]=-tune[i]
      }
     if(tune[i]>4)
      { 
      t=(floor(tune[i]/4)+1)
      X[i,]=X[i,]/t
      tune[i]=tune[i]/t
      }
    h[i]=exp(tune[i])
    y[i]<-rpois(n=1,lambda=h[i]) 
     }
    }
    if(model=="logistic")
    { 
     for(i in 1:n)
      {
       tune[i]=X[i,]%*%beta
       if (abs(tune[i])>5)
       {
       t=floor(abs(tune[i])/4)+1
       X[i,]=X[i,]/t
       tune[i]=tune[i]/t     
       }
      h[i]=exp(tune[i])/(1+exp(tune[i]))
      y[i]<-rbinom(n=1,size=1,prob=h[i]) 
     }
    }
    if(model=="negative_binomial")
    {
      for(i in 1:n)
     {
      tune[i]=X[i,]%*%beta
      if(tune[i]<0)
     {
      X[i,]=-X[i,]
      tune[i]=-tune[i]
     }
     if(tune[i]>4)
     { 
      t=(floor(tune[i]/4)+1)
      X[i,]=X[i,]/t
      tune[i]=tune[i]/t
     }
     h[i]=exp(tune[i])
     y[i]<-rpois(n=1,lambda=h[i]) 
     }
   }
     
    output=list(X=X,Y=y)
    return(output)
}
  