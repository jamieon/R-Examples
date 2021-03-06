
##################### Soft thresholding estimator for covariance matrix ############################
##################### Apply threholding on the correlation matrix       ############################
##################### Calculate the covariance estimator by applying sample variances   ############

softt <- function(m, th, Cor=TRUE) 
  
{
   
  l <- length(th)
  
  d <- diag(m)
  
  dm <- dim(m)
  
  if (Cor==TRUE)
    
  {
    
    m <-cov2cor(m)
    
  } 
  
  res <- array(m, c(dm[1], dm[2], l))
  
  if (Cor==FALSE)
    
  {
    
    for (i in 1:l) 
      
    {
      
      res[,,i] <- sign(res[,,i]) * pmax(abs(res[,,i]) - th[i], 0)
      
      diag(res[,,i]) <- d
      
    }
    
  }
  
  if (Cor==TRUE)
    
  {
    
    for (i in 1:l) 
      
    {
      
      res[,,i] <- sign(res[,,i]) * pmax(abs(res[,,i]) - th[i], 0)
      
      diag(res[,,i]) <- 1
      
      res[,,i]<-sqrt(diag(d))%*%res[,,i]%*%sqrt(diag(d))
      
    }
    
  }
  
  res
  
}
