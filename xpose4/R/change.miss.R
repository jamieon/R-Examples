# Xpose 4
# An R-based population pharmacokinetic/
# pharmacodynamic model building aid for NONMEM.
# Copyright (C) 1998-2004 E. Niclas Jonsson and Mats Karlsson.
# Copyright (C) 2005-2008 Andrew C. Hooker, Justin J. Wilkins, 
# Mats O. Karlsson and E. Niclas Jonsson.
# Copyright (C) 2009-2010 Andrew C. Hooker, Mats O. Karlsson and 
# E. Niclas Jonsson.

# This file is a part of Xpose 4.
# Xpose 4 is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation, either version 3
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License
# along with this program.  A copy can be cound in the R installation
# directory under \share\licenses. If not, see http://www.gnu.org/licenses/.

"change.miss" <- function(object, classic=FALSE)
{
  data <- object
  cat("\nPlease type the number to be treated as missing data (it is currently\n")
  cat("set to",data@Prefs@Miss,") (0=exit)\n")
  ans <- readline()
  if(ans == "0") 
    return(cat(""))

  if (is.na(as.numeric(ans))) {
    ans <- NULL
    return(cat("The data value must be numeric.\n"))
    # Recall(object)
  }
  
  if (!is.na(as.numeric(ans))) {
    data@Prefs@Miss <- as.numeric(ans)
        if (classic==TRUE) {
          c1<-call("assign",paste("xpdb", object@Runno, sep = ""), data, immediate=T, envir = .GlobalEnv)
          eval(c1)
          c2<-call("assign",pos = 1, ".cur.db", eval(as.name(paste("xpdb", object@Runno, sep = ""))))
          eval(c2)
          return(cat(""))
          
        } else {
          return(data)
        }
  }

}
