################
#R and Jags don't have same shape and scale parameterization 
# http://r.789695.n4.nabble.com/dgamma-in-jags-within-r-td3803600.html
#This function allows you to see how density plots differ btw  R and Jags
################

jagsgamma <- function(x, r, mu) {(mu^r*x^(r-1)*exp(-mu*x))/gamma(r)}


#function to convet 
p.both.gamma <- function(x, r.jags, mu.jags, ylab = "Density", ...) {
  
  ## plot the density using the formula of jags
  matplot(x, cbind(jagsgamma(x, r.jags, mu.jags),
                   dgamma(x, shape=r.jags, rate=mu.jags)),
          type="l", lty=1, ylab=ylab, ...)
  
  mtext(substitute(list(r[jags] == R, mu[jags] == M),
                   as.list(formatC(c(R=r.jags, M=mu.jags)))))
  legend("topright", c("jagsgamma", "dgamma"), lty=1, col=1:2, bty = "n")
}


## But it is not at all with these parameters:

#Thinking about sigma2 
x <- seq(0,1, by=0.001)
p.both.gamma(x, r.jags = .001, mu.jags = 0.001)


p.both.gamma(x, r.jags = 1.2, mu.jags = 1.5)


# flat
x <- seq(1e-4,1, by=1e-4)
p.both.gamma(x, r.jags = .001, mu.jags = 0.001)

# not flat
x <- seq(1e-4,1, by=1e-4)
p.both.gamma(x, r.jags = 2, mu.jags = 10)
abline(v=0.1)


# Tau2R came out as ~0.6
x <- seq(1e-4,1, by=1e-4)
p.both.gamma(x, r.jags = 5, mu.jags = 7)
abline(v=0.6)


#Thinking about theta
x <- seq(0,30, by=0.1)
p.both.gamma(x, r.jags = .6, mu.jags = .5)

p.both.gamma(x, r.jags = 10, mu.jags = .6)


#Thinking about theta
x <- seq(0,1, by=0.001)
p.both.gamma(x, r.jags = 1.4, mu.jags = 4)
abline(v=0.1)


#Thinking about eta
x <- seq(0,1, by=0.001)
p.both.gamma(x, r.jags = 1.2, mu.jags = 2.4)
abline(v=0.1)
