#   R package for Singular Spectrum Analysis
#   Copyright (c) 2009 Anton Korobeynikov <asl@math.spbu.ru>
#   
#   This program is free software; you can redistribute it 
#   and/or modify it under the terms of the GNU General Public 
#   License as published by the Free Software Foundation; 
#   either version 2 of the License, or (at your option) 
#   any later version.
#
#   This program is distributed in the hope that it will be 
#   useful, but WITHOUT ANY WARRANTY; without even the implied 
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
#   PURPOSE.  See the GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public 
#   License along with this program; if not, write to the 
#   Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
#   MA 02139, USA.

# Stubs to call PROPACK' SVD implementation

propack.svd <- function(X, neig = min(m, n), opts = list()) {
  if (is.matrix(X)) {
    m <- dim(X)[1]; n <- dim(X)[2];
    storage.mode(X) <- "double";
  } else if (.is.extmat(X)) {
    m <- .extmat.nrow(X); n <- .extmat.ncol(X);
  } else if (is(X, "extmat")) {
    m <- dim(X)[1]; n <- dim(X)[2]
    X <- X@.xData
  } else {
    stop('unsupported matrix type for SVD')
  }

  storage.mode(neig) <- "integer"
  storage.mode(opts) <- "list"
  
  .Call("propack_svd", X, neig, opts);
}

