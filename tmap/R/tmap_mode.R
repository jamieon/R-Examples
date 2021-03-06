#' Set tmap mode to static plotting or interactive viewing
#' 
#' Set tmap mode to static plotting or interactive viewing. The global option \code{tmap.mode} determines the whether thematic maps are plot in the graphics device, or shown as an interactive leaflet map. The function \code{tmap_mode} is a wrapper to set this global option. The convenient function \code{ttm} is a toggle switch between the two modes. Tip: use \code{tmap_mode} in scripts and \code{ttm} in the console.
#' 
#' @param mode one of
#' \describe{
#'    	\item{\code{"plot"}}{Thematic maps are shown in the graphics device. This is the default mode, and supports all tmap's features, such as small multiples (see \code{\link{tm_facets}}) and extensive layout settings (see \code{\link{tm_layout}}). It is recommended for saving static maps (see \code{\link{save_tmap}}).} 
#'    	\item{\code{"view"}}{Thematic maps are viewed interactively in the web browser or RStudio's Viewer pane. Maps are fully interactive with tiles from OpenStreetMap or other map providers. See \code{\link{tm_view}} for options related to the \code{"view"} mode. This mode generates a \code{\link[leaflet:leaflet]{leaflet}} widget, which can also be directly obtained with \code{\link{tmap_leaflet}}. With RMarkdown, it is possible to publish it to an HTML page. 
#'    	There are a couple of contraints in comparison to \code{"plot"}:
#'    	\itemize{
#'    	\item The map is always projected accoring to the Web Mercator projection. Although this projection is the de facto standard for interactive web-based mapping, it lacks the equal-area property, which is important for many thematic maps, especially choropleths (see examples from \code{\link{tm_shape}}).
#'    	\item Small multiples are not supported
#'    	\item The legend cannot be made for aesthetics regarding size, which are bubble size and line width.
#'    	\item Text labels are not supported (yet)
#'    	\item The layout options set with \code{\link{tm_layout}}) regarding map format are not used. However, the styling options still apply.}
#'    	}}
#' @return the mode before changing
#' @example ../examples/tmap_mode.R
#' @seealso \href{../doc/tmap-modes.html}{\code{vignette("tmap-modes")}}, \code{\link{tm_view}} for viewing options, and \code{\link{tmap_leaflet}} for obtaining a leaflet widget
#' @export
tmap_mode <- function(mode=c("plot", "view")) {
	current.mode <- getOption("tmap.mode")
	if (is.null(match.call(expand.dots = TRUE)[-1])) {
		message("current tmap mode is \"", current.mode, "\"")
	} else {
		mode <- match.arg(mode)
		options(tmap.mode=mode)
		if (mode=="plot") {
			message("tmap mode set to plotting")
		} else {
			message("tmap mode set to interactive viewing")
		}
	}
	invisible(current.mode)
}	

#' @rdname tmap_mode
#' @export
ttm <- function() {
	current.mode <- getOption("tmap.mode")
	tmap_mode(ifelse(current.mode=="plot", "view", "plot"))
	invisible(current.mode)
}

#' Set the default tmap style
#' 
#' Set the default tmap style, which is contained in the global option \code{tmap.style}.
#' 
#' @param style name of the style. The function \code{tm_style_<style>} should exist and be a wrapper of \code{\link{tm_layout}}. The default style when loading the package is \code{"white"}, which corresponds to the function \code{\link{tm_style_white}}.
#' @return the style before changing
#' @seealso \code{\link{tm_layout}} for predefined styles, and \code{\link{style_catalogue}} to create a style catelogue of all available styles.
#' @example ../examples/tmap_style.R
#' @export
tmap_style <- function(style) {
	current.style <- getOption("tmap.style")
	if (missing(style)) {
		message("current tmap style is \"", current.style, "\"")
	} else {
		obs <- c(ls(), ls("package:tmap"))
		fname <- paste("tm_style", style, sep="_")
		if (!fname %in% obs) stop("current style \"" , style, "\" unknown, i.e. the function \"" , fname, "\" does not exist.")
		options(tmap.style=style)
		message("tmap style set to \"", style, "\"")
	}
	invisible(current.style)
}
