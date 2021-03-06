# Name   : sensitivity.analysis
# Desc   : Generic call for sensitivity analysis methods
# Date   : 2012/18/06
# Author : Boelle, Obadia
###############################################################################


# Function declaration

sensitivity.analysis=function#Sensitivity analysis of basic reproduction ratio to begin/end dates
### Sensitivity analysis of reproduction ratio using supported estimation methods.
##details<< This is a generic call function to use either sa.time or sa.GT. Argument must be chosent accordingly to sa.type.
##Please refer to \code{\link{sa.time}} and \code{\link{sa.GT}} for further details about arguments.

(incid, ##<< incident cases
 GT=NULL, ##<< generation time distribution
 begin=NULL, ##<< Vector of begins date of the estimation of epidemic
 end=NULL, ##<< Vector of end dates of estimation of the epidemic
 ##details<<'begin' and 'end' vector must have the same length for the sensitivity analysis to run.
 ##They can be provided either as "dates" or "numeric" values, depending on the other parameters (see \code{\link{check.incid}}).
 ##If some begin/end dates overlap, they are ignored, and corresponding uncomputed data are set to NA.
 ##Also, note that unreliable Rsquared values are achieved for very small time period (begin ~ end).
 ##These values are not representative of the epidemic outbreak behaviour.
 est.method=NULL, ##<< Estimation method used for sensitivity analysis
 sa.type, ##<<string argument to choose between "time" and "GT" sensitivity analysis.
 res=NULL, ##<< If specified, will extract most of data from a R0.R-class result already generated by est.R0 and run sensitivity analysis on it.
 GT.type=NULL, ##<< Type of distribution for GT (see GT.R for details)
 GT.mean.range=NULL, ##<< mean used for all GT distributions throughout the simulation
 GT.sd.range=NULL, ##<< Range of standard deviation used for GT distributions. Must be provided as a vector.
 t=NULL, ##<< Dates vector to be passed to estimation function
 date.first.obs=NULL, ##<< Optional date of first observation, if t not specified
 time.step=1, ##<< Optional. If date of first observation is specified, number of day between each incidence observation
 ... ##<< parameters passed to inner functions
 )


# Code

{
  #Depending on argument "sa.type", a different sub-routine is called, with varying input arguments
  if (is.null(sa.type)) {
    stop("argument sa.type should be either \"time\" or \"GT\".")
  }
  else if ((sa.type == "time") && (!is.null(res))) {
    sa.object <- sa.time(res=res, begin=begin, end=end, ...)
  }

  else if ((sa.type == "time") && (is.null(res))) {
    if ((is.null(GT)) | (is.null(est.method))) {
      stop("Missing input argument (probably GT or est.method). Please check sa.time documentation for further details.")
    }
    else {
      sa.object=sa.time(incid=incid, GT=GT, begin=begin, end=end, est.method=est.method, t=t, date.first.obs=date.first.obs, time.step=time.step, res=res, ...)
    }
          
  }
  else if (sa.type == "GT") {
    if ((is.null(GT.type)) | (is.null(GT.mean.range)) | (is.null(GT.sd.range)) | (is.null(est.method))) {
      stop("Missing input argument (probably GT.type, GT.mean.range, GT.sd.range or est.method). Please check sa.time documentation for further details.")
    }
    else {
      sa.object=sa.GT(incid=incid, GT.type=GT.type, GT.mean.range=GT.mean.range, GT.sd.range=GT.sd.range, begin=begin, end=end, est.method=est.method, t=t, date.first.obs=date.first.obs, time.step=time.step, ...)
    }
  }
  else {
    stop(paste("sa.type = ",sa.type,"is not a valid argument. Must be \"time\" or \"GT\"."))
  }
  
  return(sa.object)
  ### An sensitivity analysis object of class "R0.S" with components depending on sensitivity analysis type.
}
