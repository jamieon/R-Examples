# Purpose        : Fit a 2D or 3D regression model;
# Maintainer     : Tomislav Hengl (tom.hengl@wur.nl)
# Contributions  : Bas Kempen (bas.kempen@wur.nl) and Gerard B.M. Heuvelink (gerard.heuvelink@wur.nl) and Mario Antonio Guevara (mguevara@udel.edu); 
# Dev Status     : Alpha
# Note           : Regression families considered spatial GLMs, CART, random forest, linear mixed-effect models ...;


## Fit a GLM to spatial data:
setMethod("fit.regModel", signature(formulaString = "formula", rmatrix = "data.frame", predictionDomain = "SpatialPixelsDataFrame", method = "character"), function(formulaString, rmatrix, predictionDomain, method = list("GLM", "rpart", "randomForest", "quantregForest", "lme", "xgboost", "ranger"), dimensions = NULL, fit.family = gaussian(), stepwise = TRUE, rvgm, GLS = FALSE, steps = 100, subsample, subsample.reg, ...){

  ## parent call:
  parent_call <- as.list(substitute(list(...)))[-1]
  
  ## target variable name:
  tv <- all.vars(formulaString)[1]  
  if(!any(names(rmatrix) %in% tv)){
    stop("Target variable not found in the 'rmatrix' object.")
  }
  ## reserved names:
  if(any(names(rmatrix) %in% paste(tv, "residual", sep="."))){
    warning(paste0("Name mismatch in the rmatrix: '", tv, ".residual' already in use"))
  }
  
  ## spatial coordinates (column names):
  xyn <- attr(predictionDomain@bbox, "dimnames")[[1]]
  ## try to guess the dimensions:
  if(is.null(dimensions)){
    if(length(xyn)==2){ dimensions = "2D" }
    if(length(xyn)==3){ dimensions = "3D" }    
  }  
  if(!any(names(rmatrix) %in% xyn)){
       stop(paste("Column names:", paste(xyn[which(!(xyn %in% names(rmatrix)))], collapse=", "), "could not be located in the regression matrix"))
  }

  ## check if the method exists:
  if(length(method)>1){ method <- method[[1]] }
  if(!any(method %in% list("GLM", "rpart", "randomForest", "quantregForest", "lme", "xgboost", "ranger"))){ stop(paste(method, "method not available.")) }
  
  ## subsample regression if necessary:
  s <- 1:nrow(rmatrix)
  if(!missing(subsample.reg)){
     if(nrow(rmatrix) > subsample.reg){
       message(paste0("Subsetting regression matrix to ", subsample.reg, " observations..."))
       s <- sample(1:nrow(rmatrix), subsample.reg)
     }
  }
  rmatrix.s <- rmatrix[s,]
   
  ## 1. REGRESSION MODEL FITTING
  if(method == "lme"){
    message("Fitting a Mixel-effect linear model...")
    if(requireNamespace("nlme", quietly = TRUE)){
      if(!missing(subsample.reg)){ message("Ignoring 'subsample.reg' argument...") }
      ## check if the random component is defined:
      if(any(names(parent_call) %in% "random")){
        rgm <- nlme::lme(formulaString, random=eval(parent_call[["random"]]), data=rmatrix, na.action=na.omit)
      } else {
        rgm <- nlme::lme(formulaString, data=rmatrix, na.action=na.omit)
      }
      ## extract the residuals:
      if(any(names(rgm) == "na.action")){  rmatrix <- rmatrix[-rgm$na.action,] }
      rmatrix[,paste(tv, "residual", sep=".")] <- resid(rgm)
    } else {
      stop("Package 'nlme' not available")
    }
  }
  
  if(method == "GLM"){  
    ## fit/filter the regression model:
    if(GLS == TRUE & fit.family$family == "gaussian" & fit.family$link == "identity"){
      if(!dimensions == "2D"){ stop("Fitting of the models using the GLS option possible with '2D' data only") }
      message("Fitting a LM using Generalized Least Squares...")
      if(requireNamespace("nlme", quietly = TRUE)){
        rgm <- nlme::gls(formulaString, rmatrix.s, correlation=nlme::corExp(nugget=TRUE), na.action=na.omit)
        ## extract the residuals:
        rmatrix[,paste(tv, "residual", sep=".")] <- rmatrix[,tv] - predict(rgm, rmatrix)
      } else {
      stop("Package 'nlme' not available")
      }
    } else {
      #if(!missing(subsample.reg)){ message("Ignoring 'subsample.reg' argument...") }
      if(all(c("family","link") %in% names(fit.family))){
        if(fit.family$family=="gaussian"&fit.family$link=="identity"){
          message("Fitting a linear model...")
        } 
      } else {  
        message("Fitting a GLM...")
      }
      if(any(names(parent_call) %in% "weights")){ 
        rmatrix$weights <- eval(parent_call[['weights']])
        rgm <- glm(formulaString, data=rmatrix, family=fit.family, weights=weights)
      } else {
        rgm <- glm(formulaString, data=rmatrix, family=fit.family)
      }
      if(stepwise == TRUE){
        rgm <- step(rgm, trace=0, steps=steps)
      }      
      ## extract the response residuals: [http://stackoverflow.com/questions/2531489/understanding-glmresiduals-and-residglm]
      if(any(names(rgm) == "na.action")){  rmatrix <- rmatrix[-rgm$na.action,] }
      rmatrix[,paste(tv, "residual", sep=".")] <- resid(rgm, type="response") 
    }
  }
  
  if(method == "rpart"){
    ## fit/filter the regression model:
    message("Fitting a regression tree model...")
    if(requireNamespace("rpart", quietly = TRUE)){
      rgm <- rpart::rpart(formulaString, data=rmatrix.s)
      if(stepwise == TRUE){
        ## TH: "A good choice of cp for pruning is often the leftmost value for which the mean lies below the horizontal line"
        ## BK: determine row in complexity table with smallest xerror:
        minerror <- min(seq_along(rgm$cptable[,4L])[rgm$cptable[,4L] == min(rgm$cptable[,4L])])
        ## BK: select starting value for evaluation of xerror:
        xerr <- rgm$cptable[1L,4L]
        ## BK: compute 1-SE value:
        dum <- (rgm$cptable[,4L] + rgm$cptable[,5L])[minerror]
        ## BK determine row in complexity table for which xerror is smaller than 1-SE:
        i <- 0
        while (xerr > dum && i <= nrow(rgm$cptable)) {
          i <- i+1L  
          xerr <- rgm$cptable[i,4L]
        }
        # BK: obtain cp parameter and number of splits for selected row:
        cpar <- rgm$cptable[i,1L]
        nsplit <- rgm$cptable[i,2L]
        message(paste("Estimated Complexity Parameter (for prunning):", signif(cpar, 4)))
        rgm <- rpart::prune(rgm, cp=cpar)
      }  
    } else {
      stop("Package 'rpart' not available")
    }
  }
  
  if(method == "randomForest"|method == "quantregForest"|method == "ranger"|method == "xgboost"){
    if(requireNamespace("randomForest", quietly = TRUE)&requireNamespace("ranger", quietly = TRUE)){
      ## fit/filter the regression model:
      ## NA's not permitted and need to be filtered out:
      f <- stats::complete.cases(rmatrix.s[,all.vars(formulaString)])
      rmatrix.s <- rmatrix.s[f,]    
      if(method == "randomForest"|method == "ranger"){
        message("Fitting a randomForest model...")
        if(any(names(parent_call) %in% "mtry")){
          mtry <- eval(parent_call[["mtry"]])
          if(method == "randomForest"){
            rgm <- randomForest::randomForest(formulaString, data=rmatrix.s, importance=TRUE, na.action=na.omit, mtry=mtry)
          }
          if(method == "ranger"){
            rgm <- ranger::ranger(formulaString, data=rmatrix.s, importance="impurity", write.forest=TRUE, mtry=mtry)
          }
        } else {
          if(method == "randomForest"){
            rgm <- randomForest::randomForest(formulaString, data=rmatrix.s, importance=TRUE, na.action=na.omit)
          }
          if(method == "ranger"){
            rgm <- ranger::ranger(formulaString, data=rmatrix.s, importance="impurity", write.forest=TRUE)
          }
        }
      } else {
        if(method == "xgboost"){
           if(requireNamespace("xgboost", quietly = TRUE)&requireNamespace("caret", quietly = TRUE)){
             message("Fitting a Gradient Boosting model using the 'xgboost' package...")
             ctrl <- caret::trainControl(method="cv", number=2, repeats=1)
             gb.tuneGrid <- expand.grid(eta=0.3, nrounds=c(50,100), max_depth=2:3, gamma=0, colsample_bytree=0.8, min_child_weight=1)
             rgm <- caret::train(formulaString, data=rmatrix.s, method="xgbTree", trControl=ctrl, tuneGrid=gb.tuneGrid)
           } else {
             stop("Packages 'caret', 'xgboost' not available")
           }
        }
        if(method == "quantregForest"){ 
          ## TH: the quantreg package developed by Nicolai Meinshausen <meinshausen@stats.ox.ac.uk> is more computationally demanding, but more flexible      
          if(requireNamespace("quantregForest", quietly = TRUE)){
            rgm <- quantregForest::quantregForest(y=eval(formulaString[[2]], rmatrix.s), x=rmatrix.s[,all.vars(formulaString)[-1]], importance=TRUE)
            attr(rgm$y, "name") <- tv
          } else {
            stop("Package 'quantregForest' not available")
          }
        }
      }
    } else {
      stop("Packages 'randomForest', 'ranger' not available")
    }
  }
  
  ## Extract residuals:
  if(method == "quantregForest"){
    ## breaks if there are incomplete obs:
    rmatrix[f,paste(tv, "residual", sep=".")] <- rmatrix[f,tv] - predict(rgm, newdata=rmatrix[f,attr(rgm$forest$ncat, "names")], what=.5)
  } 
  if(method == "randomForest"|method == "rpart"){
    rmatrix[,paste(tv, "residual", sep=".")] <- rmatrix[,tv] - predict(rgm, newdata=rmatrix, na.action = na.pass)
  }
  
  if(method == "ranger"){
    if(requireNamespace("ranger", quietly = TRUE)){
      rmatrix[f,paste(tv, "residual", sep=".")] <- rmatrix[f,tv] - predict(rgm, rmatrix[f,])$predictions
    } else {
      stop("Package 'ranger' not available")
    }
  }
  if(method == "xgboost"){
    if(requireNamespace("xgboost", quietly = TRUE)){
      rmatrix[,paste(tv, "residual", sep=".")] <- rmatrix[,tv] - predict(rgm, newdata=rmatrix, na.action = na.pass)
    } else {
      stop("Package 'xgboost' not available")
    }
  }
  ## TH: add more regression models here...
  
  ## test the normality of residuals:
  if(length(rmatrix[,paste(tv, "residual", sep=".")])>4999){
    # subset residuals if necessary...
    x = rmatrix[sample(1:nrow(rmatrix), 4999), paste(tv, "residual", sep=".")]
  } else {
    x = rmatrix[,paste(tv, "residual", sep=".")]
  }
  st <- shapiro.test(x)
  if(st$p.value < 0.05|is.na(st$p.value)){
    ## try second test:
    if(requireNamespace("nortest", quietly = TRUE)){
      at = nortest::ad.test(x)
      if(at$p.value < 0.05|is.na(at$p.value)){
        warning(paste(st$method, "and", at$method, "report probability of < .05 indicating lack of normal distribution for residuals"), call. = FALSE, immediate. = TRUE)
      }
    }
  }

  ## 2. VARIOGRAM FITTING
  if(any(names(parent_call) %in% "cutoff")){
     cutoff <- eval(parent_call[["cutoff"]])
  } else {
     cutoff <- NULL
  }
  if(missing(subsample)){
    subsample <- nrow(rmatrix)
  }
  if(missing(rvgm)&GLS==FALSE){
  ## If variogram is not defined, try to fit variogram 2D or 3D data:
    if(dimensions == "2D"){ 
      message("Fitting a 2D variogram...")
      rvgm <- fit.vgmModel(as.formula(paste0(tv, ".residual ~ 1")), rmatrix = rmatrix, predictionDomain = predictionDomain, dimensions = "2D", subsample=subsample, cutoff=cutoff) 
    }
    if(dimensions == "3D"){ 
      message("Fitting a 3D variogram...")
      rvgm <- fit.vgmModel(as.formula(paste0(tv, ".residual ~ 1")), rmatrix = rmatrix, predictionDomain = predictionDomain, dimensions = "3D", subsample=subsample, cutoff=cutoff) 
    }
    } else {
      ## TH: The nlme package fits a variogram, but this is difficult to translate to gstat format:
      if(missing(rvgm)&any(class(rgm)=="gls")){
           rvgm <- fit.vgmModel(as.formula(paste0(tv, ".residual ~ 1")), rmatrix = rmatrix, predictionDomain = predictionDomain, dimensions = "2D", subsample=subsample, cutoff=cutoff)
      } else { 
        ## Use a pure nugget effect if variogram is set to NULL
        if(is.null(rvgm)){
          rvgm <- fit.vgmModel(as.formula(paste0(tv, ".residual ~ 1")), rmatrix = rmatrix, predictionDomain = predictionDomain, dimensions = dimensions, vgmFun = "Nug", subsample=subsample)
        } else {
          xyn = attr(predictionDomain@bbox, "dimnames")[[1]]
          ## create spatial points:
          coordinates(rmatrix) <- as.formula(paste("~", paste(xyn, collapse = "+"), sep=""))
          proj4string(rmatrix) = predictionDomain@proj4string
          observations = as(rmatrix, "SpatialPoints")
          ## othewise copy the variogram submitted by the user:
          svgm <- gstat::variogram(formulaString, rmatrix)
          rvgm <- list(vgm=rvgm, observations=observations, svgm=svgm)
          }
       }
  }
  
  ## TH: refit non-linear trend model using the GLS weights? This can be very time consuming and is not recommended for large data sets
  
  message("Saving an object of class 'gstatModel'...")  
  rkm <- new("gstatModel", regModel = rgm, vgmModel = as.data.frame(rvgm[[1]]), svgmModel = as.data.frame(rvgm[[3]]), sp = rvgm[[2]])
  return(rkm)

})

## end of script;