context('Symbolic Integration')

test_that('Simple polynomial expressions work',{
  ff = symbolicInt(2*x^6+9*x^3+2~x)
  gg = function(x)2*1/7*x^7+9*1/4*x^4+2*x
  expect_that(ff(seq(1,10, len=30)), equals(gg(seq(1,10, len=30)), tol=0.00001))
  
  ff = symbolicInt((2+3)*x^5+(2+9)*x^2+(8*6+2)*x~x)
  gg = function(x){(2+3)*1/(6)*x^6+(2+9)*1/(3)*x^3+(8*6+2)*1/(2)*x^2}
  expect_that(ff(seq(1,10, len=28)), equals(gg(seq(1,10, len=28)), tol=0.00001))
})

test_that('Declared variables do not interfere with constants',{
  a=5
  ff = symbolicInt((a+3)*x^7-a*4*x+a~x)
  gg = function(x,a){(a+3)*1/(8)*x^8-a*4*1/(2)*x^2+a*x}
  expect_that(ff(seq(1,10, len=26), a=2), equals(gg(seq(1,10, len=26), a=2), tol=0.00001))
})

test_that('Negative exponents on polynomials work',{
  ff = symbolicInt(3*x^-4+x^-2-x^-3~x)
  gg = function(x){3*1/(-3)*x^-3+1/(-1)*x^-1-1/(-2)*x^-2}
  expect_that(ff(seq(1,10, len=28)), equals(gg(seq(1,10, len=28)), tol=0.00001))
  
  ff = symbolicInt(3/x~x)
  gg = function(x){3*log(x)}
  expect_that(ff(seq(1,10, len=28)), equals(gg(seq(1,10, len=28)), tol=0.00001))
})

test_that('Simple trigonometric functions are working',{
  ff = symbolicInt(27*sin(3*x)~x)
  gg = function(x){-9*cos(3*x)}
  expect_that(ff(seq(1,10, len=28)), equals(gg(seq(1,10, len=28)), tol=0.00001))
  
  ff = symbolicInt(-sin(x)~x)
  gg = function(x){cos(x)}
  expect_that(ff(seq(1,10, len=28)), equals(gg(seq(1,10, len=28)), tol=0.00001))
  
})

test_that('Things break correctly', {
  expect_error(symbolicInt(sin(cos(x))~x))
  expect_error(symbolicInt(sin(x^3)~x))
  expect_error(symbolicInt(log(x+x)~x))
  expect_error(symbolicInt(x^(x)~x))
  expect_error(symbolicInt(1/x^2+1/x^3~x))
})

test_that('Everything works',{
  checkFun <- function(formula, integral){
    ff = symbolicInt(formula)
    gg = makeFun(integral)
    vars = list()
    for(i in (1:length(formals(ff)))){
      if(class(formals(ff)[[i]])=="name")
        vars[[names(formals(ff))[[i]]]] = seq(-10,10, len = 40)
    }
    expect_that(do.call(ff, vars), equals(do.call(gg, vars), tol=0.00001))
  }
  
  checkFun((r^2 - x^2)~x, r^2*x - x^3/3 ~x) # Issue 180
  checkFun(x^12+x^9-x^6+x^3-1~x, 1/13*x^13+1/10*x^10-1/7*x^7+1/4*x^4-x~x)
  checkFun((2+3)*x^5+(2+9)*x^2+(8*6+2)*x~x, (2+3)*1/(6)*x^6+(2+9)*1/(3)*x^3+(8*6+2)*1/(2)*x^2~x)
  checkFun((a+3)*y^7-a*4*y+a~y, (a+3)*1/(8)*y^8-a*4*1/(2)*y^2+a*y~y)
  checkFun(x^n~x, 1/(n+1)*x^(n+1)~x)
  checkFun(3*x^-4+x^-2-x^-3~x,3*1/(-3)*x^-3+1/(-1)*x^-1-1/(-2)*x^-2~x )
  checkFun(3/y+3*y^2~y, 3*log(y)+y^3~y)
  checkFun(((2+((3*((x))))))~x, 2*x+3/2*x^2~x)
  checkFun(3*(2*x)^2~x, 1/2*(2*x)^3~x)
  checkFun(1/(x+1)~x, log(1+x)~x)
  checkFun((x+1)^-1~x, log(1+x)~x)
  checkFun(3*sin(3*x+1)~x, -cos(3*x+1)~x)
  checkFun(sin(2*(x))~x, -1/2*cos(2*x)~x)
  checkFun(2*pi*(x/P)~x, pi/P*x^2~x)
  checkFun(3^2~y, 9*y~y)
  checkFun((x*8)^2~x, 1/24*(8*x)^3~x)
  checkFun(exp(3*x+9)~x, 1/3*exp(3*x+9)~x)
  checkFun(x^(1/2)~x, 2/3*x^(3/2)~x)
  checkFun(x^(-31/52)~x, 52/21*x^(21/52)~x)
  checkFun(2*z+2*z+2*z+2*z+2*z+2*z+2*z+2*z+2*z+2*z+2*z+2*z~z,
           z^2+z^2+z^2+z^2+z^2+z^2+z^2+z^2+z^2+z^2+z^2+z^2~z)
})


test_that('trig subs work', {
  eq <- symbolicInt(1/sqrt(-2*x^2+4*x+3)~x)
  eq2 <- antiD(1/sqrt(-2*x^2+4*x+3)~x, force.numeric=TRUE)
  
  #standard dev. really small, indicates that the difference between the numerical integration and 
  #the symbolic one is a constant.
  vals1 <- eq(seq(-.5,1,len=10), C=-eq(0))
  vals2 <- eq2(seq(-.5,1,len=10))
  expect_that(sd(vals2-vals1), equals(0, tol=0.00001))
  
  eq <- symbolicInt(1/(3*x^2+x+9)~x)
  eq2 <- antiD(1/(3*x^2+x+9)~x, force.numeric=TRUE)
  
  vals1 <- eq(seq(-.5,1,len=10), C=-eq(0))
  vals2 <- eq2(seq(-.5,1,len=10))
  expect_that(sd(vals2-vals1), equals(0, tol=0.00001))
})