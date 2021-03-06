library(survival)

# A contrived example for the tt function
#
mkdata <- function(n, beta) {
    age <- runif(n, 20, 60)
    x <- rbinom(n, 1, .5)

    futime <- rep(40, n)   # everyone has 40 years of follow-up
    status <- rep(0, n)
    dtime <-  runif(n/2, 1, 40)  # 1/2 of them die
    dtime <- sort(dtime)

    # The risk is set to beta[1]*x + beta[2]* f(current_age)
    #   where f= 0 up to age 40, rises linear to age 70, flat after that
    for (i in 1:length(dtime)) {
        atrisk <- (futime >= dtime[i])
        c.age <- age + dtime
        age2 <- pmin(30, pmax(0, c.age-40))
        xbeta <- beta[1]*x + beta[2]*age2
        
        # Select a death according to risk
        risk <- ifelse(atrisk, exp(xbeta), 0)
        dead <- sample(1:n, 1, prob=risk/sum(risk))
        
        futime[dead] <- dtime[i]
        status[dead] <- 1
    }
    data.frame(futime=futime, status=status, age=age, x=x, risk=risk)
}
tdata <- mkdata(500, c(log(1.5), 2/30))

fit1 <- coxph(Surv(futime, status) ~ x + pspline(age), tdata)
fit2 <- coxph(Surv(futime, status) ~ x + tt(age), tdata,
              tt= function(x, t, ...) pspline(x+t))

dfit <- coxph(Surv(futime, status) ~ x + tt(age), tdata,
              tt= function(x, t, ...) x+t, iter=0, x=T)

#
# Check that cluster, weight, and offset were correctly expanded
#
tdata <- data.frame(tdata, grp=sample(1:100, 500, replace=TRUE),
                    casewt = sample(1:5, 500, replace=TRUE),
                    zz = rnorm(500))
dfit2 <- coxph(Surv(futime, status) ~ x + tt(age) + offset(zz) + cluster(grp),
               weight=casewt, data=tdata,
               tt= function(x, t, ...) x+t)
