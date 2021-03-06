`imwd` <-
function(image, filter.number = 10., family = "DaubLeAsymm", type = "wavelet",
bc = "periodic", RetFather = TRUE, verbose = FALSE)
{
###
#
# This is a minor modification of WaveThresh imwd function which contains
# a bug when performing the stationary (non-decimated) wavelet transform.
# 
###
if(verbose == TRUE)
   cat("Argument checking...")
if(nrow(image) != ncol(image))
   stop("Number of rows and columns in image are not identical")
#
#Select wavelet filter
#
if(verbose == TRUE) #
   cat("...done\nFilter...")
filter <- filter.select(filter.number = filter.number, family = family)
#
# Check that Csize is a power of 2
#
Csize <- #
nrow(image)
nlev <- IsPowerOfTwo(Csize)
#
# Set-up first/last database
#
if(is.na(nlev)) #
   stop(paste("The image size (", Csize, ") is not a power of 2"))
if(verbose == TRUE)
   cat("...selected\nFirst/last database...")
fl.dbase <- first.last(LengthH = length(filter$H), DataLength = Csize,
bc = bc, type = type)
first.last.c <- fl.dbase$first.last.c
#
#
# Set up answer list
#
first.last.d <- fl.dbase$first.last.d
#
#
image.decomp <- #
list(nlevels = nlev, fl.dbase = fl.dbase, filter = filter, type = type,
bc = bc, date = date())
#
# Ok, go round loop doing decompositions
#
if(verbose == TRUE) #
   cat("...built\n")
nbc <- switch(bc,
periodic = 1.,
symmetric = 2.)
if(is.null(nbc))
   stop("Unknown boundary handling")
if(type == "station" && bc == "symmetric")
   stop("Cannot do stationary transform with symmetric boundary conditions")
ntype <- switch(type,
wavelet = 1.,
station = 2.)
#
#Load up original image
#
if(is.null(ntype)) #
   stop("Unknown type of transform")
smoothed <- as.vector(image)
#
#If type="wavelet" then we do this
#
if(verbose == TRUE) {
   cat(bc, " boundary handling\n")
  cat("Decomposing...")
}
if(type == "wavelet") {
   for(level in seq(nrow(first.last.d), 1., -1.)) {
   if(verbose == TRUE)
      cat(level - 1., "")
      LengthCin <- first.last.c[level + 1., 2.] - 
      first.last.c[level + 1., 1.] + 1.
      LengthCout <- first.last.c[level, 2.] - first.last.c[level, 1.] + 1.
      LengthDout <- first.last.d[level, 2.] - first.last.d[level, 1.] + 1.
      ImCC <- rep(0., (LengthCout * LengthCout))
      ImCD <- rep(0., (LengthCout * LengthDout))
      ImDC <- rep(0., (LengthDout * LengthCout))
      ImDD <- rep(0., (LengthDout * LengthDout))
      error <- 0.
      z <- .C("StoIDS", C = as.double(smoothed), Csize = as.integer(LengthCin), firstCin = 
      as.integer(first.last.c[level + 1., 1.]),
      H = as.double(filter$H),LengthH = as.integer(length(filter$H)),
      LengthCout = as.integer(LengthCout),firstCout = as.integer(first.last.c[level,1.]),
      lastCout = as.integer(first.last.c[level, 2.]),
      LengthDout = as.integer(LengthDout),
      firstDout = as.integer(first.last.d[level, 1.]),
      lastDout = as.integer(first.last.d[level, 2.]),
      ImCC = as.double(ImCC),ImCD = as.double(ImCD),ImDC = as.double(ImDC),ImDD = as.double(ImDD),
      nbc = as.integer(nbc),ntype = as.integer(ntype),error = as.integer(error),
      PACKAGE = "LS2W")
      error <- z$error
      if(error != 0.) {
         cat("Error was ", error, "\n")
         stop("Error reported")
      }
   smoothed <- z$ImCC
   if(RetFather == TRUE) {
      nm <- lt.to.name(level - 1., "CC")
      image.decomp[[nm]] <- z$ImCC
   }
   nm <- lt.to.name(level - 1., "CD")
   image.decomp[[nm]] <- z$ImCD
   nm <- lt.to.name(level - 1., "DC")
   image.decomp[[nm]] <- z$ImDC
   nm <- lt.to.name(level - 1., "DD")
   image.decomp[[nm]] <- z$ImDD
  }
}
else if(type == "station") {
   for(level in seq(nrow(first.last.d), 1., -1.)) {
   if(verbose == TRUE)
      cat(level - 1., "")
      LengthCin <- first.last.c[level + 1., 2.] - 
      first.last.c[level + 1., 1.] + 1.
      LengthCout <- first.last.c[level, 2.] - first.last.c[
      level, 1.] + 1.
      LengthDout <- first.last.d[level, 2.] - first.last.d[
      level, 1.] + 1.
      ImCC <- rep(0., (LengthCout * LengthCout))
      ImCD <- rep(0., (LengthCout * LengthDout))
      ImDC <- rep(0., (LengthDout * LengthCout))
      ImDD <- rep(0., (LengthDout * LengthDout))
      error <- 0.
      if(level == nrow(first.last.d))
      stepfactor <- 1.
      else stepfactor <- stepfactor * 2.
      z <- .C("StoIDSIE",
      C = as.double(smoothed),
      Csize = as.integer(LengthCin),
      firstCin = as.integer(first.last.c[level + 1.,1.]),
      H = as.double(filter$H),
      LengthH = as.integer(length(filter$H)),
      LengthCout = as.integer(LengthCout),
      firstCout = as.integer(first.last.c[level,1.]),
      lastCout = as.integer(first.last.c[level, 2.]),
      LengthDout = as.integer(LengthDout),
      firstDout = as.integer(first.last.d[level, 1.]),
      lastDout = as.integer(first.last.d[level, 2.]),

      ImCC = as.double(ImCC),
      ImCD = as.double(ImCD),
      ImDC = as.double(ImDC),
      ImDD = as.double(ImDD),
      nbc = as.integer(nbc), 
      ntype = as.integer(ntype),
      error = as.integer(error),
      stepfactor = as.integer(stepfactor),
      PACKAGE = "LS2W")
      error <- z$error
      if(error != 0.) {
         cat("Error was ", error, "\n")
         stop("Error reported")
      }
      smoothed <- z$ImCC
      if(RetFather == TRUE) {
      nm <- lt.to.name(level - 1., "CC")
      image.decomp[[nm]] <- z$ImCC
   }
   nm <- lt.to.name(level - 1., "CD")
   image.decomp[[nm]] <- z$ImCD
   nm <- lt.to.name(level - 1., "DC")
   image.decomp[[nm]] <- z$ImDC
   nm <- lt.to.name(level - 1., "DD")
   image.decomp[[nm]] <- z$ImDD
}
}
if(verbose == TRUE)
   cat("\nReturning answer...\n")
image.decomp$w0Lconstant <- smoothed
image.decomp$bc <- bc
image.decomp$date <- date()
class(image.decomp) <- "imwd"
image.decomp
}

