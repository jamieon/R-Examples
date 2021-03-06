#' Function to remove nodes from network, with shiny only.
#'
#' Function to remove nodes from network, with shiny only. 
#' 
#'@param graph : a \code{\link{visNetworkProxy}}  object
#'@param id : vector of id, nodes to remove
#'
#'@seealso \link{visNodes} for nodes options, \link{visEdges} for edges options, \link{visGroups} for groups options, 
#'\link{visLegend} for adding legend, \link{visOptions} for custom option, \link{visLayout} & \link{visHierarchicalLayout} for layout, 
#'\link{visPhysics} for control physics, \link{visInteraction} for interaction, \link{visNetworkProxy} & \link{visFocus} & \link{visFit} for animation within shiny,
#'\link{visDocumentation}, \link{visEvents}, \link{visConfigure} ...
#' 
#' @examples
#'\dontrun{
#'
#'# have a look to : 
#'shiny::runApp(system.file("shiny", package = "visNetwork"))
#'
#'}
#'
#'@export

visRemoveNodes <- function(graph, id){

  if(!any(class(graph) %in% "visNetwork_Proxy")){
    stop("Can't use visRemoveNodes with visNetwork object. Only within shiny & using visNetworkProxy")
  }

  data <- list(id = graph$id, rmid = id)
  
  graph$session$sendCustomMessage("visShinyRemoveNodes", data)

  graph
}
