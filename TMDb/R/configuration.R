configuration <-
function(api_key){
    
    url <- fromJSON(GET(url=paste("http://api.themoviedb.org/3/configuration?api_key=", 
                                  api_key, sep =""))$url)
    return(url)

}
