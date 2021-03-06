prederrJM.jointModel <-
function (object, newdata, Tstart, Thoriz, lossFun = c("absolute", "square"), 
                               interval = FALSE, idVar = "id", simulate = FALSE, M = 100, ...) {
    if (!inherits(object, "jointModel"))
        stop("Use only with 'jointModel' objects.\n")
    if (!is.data.frame(newdata) || nrow(newdata) == 0)
        stop("'newdata' must be a data.frame with more than one rows.\n")
    if (is.null(newdata[[idVar]]))
        stop("'idVar' not in 'newdata.\n'")
    lossFun <- if (is.function(lossFun)) {
        lf <- lossFun
        match.fun(lossFun)
    } else {
        lf <- match.arg(lossFun)
        if (lf == "absolute") function (x) abs(x) else function (x) x*x
    }
    id <- newdata[[idVar]]
    id <- match(id, unique(id))
    TermsT <- object$termsT
    SurvT <- model.response(model.frame(TermsT, newdata)) 
    Time <- SurvT[, 1]
    timeVar <- object$timeVar
    newdata2 <- newdata[Time > Tstart, ]
    SurvT <- model.response(model.frame(TermsT, newdata2)) 
    Time <- SurvT[, 1]
    delta <- SurvT[, 2]
    aliveThoriz <- newdata2[Time > Thoriz & newdata2[[timeVar]] <= Tstart, ]
    deadThoriz <- newdata2[Time <= Thoriz & delta == 1 & newdata2[[timeVar]] <= Tstart, ]
    indCens <- Time < Thoriz & delta == 0 & newdata2[[timeVar]] <= Tstart
    censThoriz <- newdata2[indCens, ]
    nr <- length(unique(newdata2[[idVar]])) 
    idalive <- unique(aliveThoriz[[idVar]])
    iddead <- unique(deadThoriz[[idVar]])
    idcens <- unique(censThoriz[[idVar]])
    Surv.aliveThoriz <- survfitJM(object, newdata = aliveThoriz, idVar = idVar, simulate = simulate, M = M,
                                  survTimes = Thoriz, last.time = rep(Tstart, length(idalive)))
    Surv.deadThoriz <- survfitJM(object, newdata = deadThoriz, idVar = idVar, simulate = simulate,
                                 survTimes = Thoriz, last.time = rep(Tstart, length(iddead)))
    Surv.aliveThoriz <- sapply(Surv.aliveThoriz$summaries, "[", 2)
    Surv.deadThoriz <- sapply(Surv.deadThoriz$summaries, "[", 2)
    if (nrow(censThoriz)) {
        Surv.censThoriz <- survfitJM(object, newdata = censThoriz, idVar = idVar, simulate = simulate, M = M,
                                     survTimes = Thoriz, last.time = rep(Tstart, length(idcens)))
        tt <- Time[indCens]
        weights <- survfitJM(object, newdata = censThoriz, idVar = idVar, simulate = simulate, M = M,
                             survTimes = Thoriz, last.time = tt[!duplicated(censThoriz[[idVar]])])
        Surv.censThoriz <- sapply(Surv.censThoriz$summaries, "[", 2)
        weights <- sapply(weights$summaries, "[", 2)
    } else {
        Surv.censThoriz <- weights <- NA
    }
    prederr <- if (!interval) {
        (1/nr) * sum(lossFun(1 - Surv.aliveThoriz), lossFun(0 - Surv.deadThoriz),
                     weights * lossFun(1 - Surv.censThoriz) + (1 - weights) * lossFun(0 - Surv.censThoriz))
    } else {
        TimeCens <- exp(object$y$logT)
        deltaCens <- 1 - object$y$event
        KMcens <- survfit(Surv(TimeCens, deltaCens) ~ 1)
        times <- TimeCens[TimeCens > Tstart & TimeCens < Thoriz & !deltaCens]
        times <- sort(unique(times))
        k <- as.numeric(table(times))
        w <- summary(KMcens, times = Tstart)$surv / summary(KMcens, times = times)$surv
        prederr.times <- sapply(times, 
                                function (t) prederrJM(object, newdata, Tstart, t,
                                                       interval = FALSE, idVar = idVar, simulate = simulate)$prederr)
        num <- sum(prederr.times * w * k, na.rm = TRUE)
        den <- sum(w * k, na.rm = TRUE)
        num / den
    }
    out <- list(prederr = prederr, nr = nr, Tstart = Tstart, Thoriz = Thoriz, interval = interval,
                classObject = class(object), nameObject = deparse(substitute(object)), lossFun = lf)
    class(out) <- "prederrJM"
    out
}
