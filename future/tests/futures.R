library("future")
library("listenv")

ovars <- ls()
oopts <- options(warn=1L, mc.cores=2L, future.debug=TRUE)

## Backward compatibility
if (getRversion() < "3.2.0") {
  names <- function(x) {
    if (class(x)[1] == "environment") {
      ls(envir=x, all.names=TRUE)
    } else {
      base::names(x)
    }
  }
}

dims <- list(
  NULL,
  c(1,6),
  c(2,3),
  c(2,3,1),
  c(2,1,3,1)
)


message("*** futures() / resolved() / values() ...")

for (cores in 1:min(3L, availableCores())) {
  message(sprintf("Testing with %d cores ...", cores))
  options(mc.cores=cores-1L)

  for (type in c("list", "environment", "listenv")) {
    message(sprintf("Type of object: %s", type))

    for (strategy in future:::supportedStrategies()) {
      message("Type of future: ", strategy)
      plan(strategy)

      for (dim in dims) {
        message("Dimensions: ", deparse(dim))

        if (type == "list") {
          x <- list()
        } else if (type == "listenv") {
          x <- listenv()
        } else if (type == "environment") {
          x <- new.env()
        }

        x$a <- 1
        x$b <- future(2)
        x$c <- 3
        if (type != "list") x$d %<-% { 4 }
        if (type != "environment") x[[6]] <- 6
        str(x)

        if (!is.null(dim)) {
          if (type != "environment") {
            names <- names(x)
            dim(x) <- dim
            dimnames(x) <- lapply(dim, FUN=function(n) letters[1:n])
            names(x) <- names
          }
        }

        f <- futures(x)
        str(f)
        if (type != "environment") {
          stopifnot(length(f) == length(x))
          stopifnot(identical(names(f), names(x)))
        }
        stopifnot(identical(dim(f), dim(x)))
        stopifnot(identical(dimnames(f), dimnames(x)))

        r <- resolved(x)
        str(r)
        if (type != "environment") {
          stopifnot(length(r) == length(x))
          stopifnot(identical(names(r), names(x)))
        }
        stopifnot(identical(dim(r), dim(x)))
        stopifnot(identical(dimnames(r), dimnames(x)))

        v <- values(x)
        str(v)
        if (type != "environment") {
          stopifnot(length(v) == length(x))
          stopifnot(identical(names(v), names(x)))
        }
        stopifnot(identical(dim(v), dim(x)))
        stopifnot(identical(dimnames(v), dimnames(x)))
      } # for (dim ...)
    } # for (strategy ...)

    message(sprintf("*** futures() - %s ... DONE", type))
  } # for (type ...)

  message(sprintf("Testing with %d cores ... DONE", cores))
} ## for (cores ...)

message("*** futures() / resolved() / values() ... DONE")

## Cleanup
plan(eager)
options(oopts)
rm(list=setdiff(ls(), ovars))
