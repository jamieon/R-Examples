# Error codes

gmum.error <- function(code, message){
    return(paste(code, ": ", message, sep=""))
}

GMUM_ERROR = "Error"
GMUM_WRONG_LIBRARY = "Error 20"
GMUM_WRONG_KERNEL = "Error 21"
GMUM_BAD_PREPROCESS = "Error 22"
GMUM_NOT_SUPPORTED = "Error 23"
GMUM_WRONG_PARAMS = "Error 24"
