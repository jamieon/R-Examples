psmall.svd <-
function(m, tol)
{
   B = crossprod(m)   # pxp matrix
   s = svd(B,nu=0)    # of which svd is easy..

   # determine rank of B  (= rank of m)
   if( missing(tol) ) 
      tol = dim(B)[1]*max(s$d)*.Machine$double.eps 
   Positive = s$d > tol                            
           
   # positive singular values of m  
   d = sqrt(s$d[Positive])
      
   # corresponding orthogonal basis vectors
   v = s$v[, Positive, drop=FALSE]
   u = m %*% v %*% diag(1/d, nrow=length(d))
  
   return(list(d=d,u=u,v=v))
}
