gaussian_fn = function(x,mu,sigma,k){
  k*exp(-1/2*(x-mu)^2/sigma^2)
}

fit_gaussian = function(x,y,mu,k){
  nls(y ~ gaussian_fn(x,mu,sigma,k), start=c(sigma=5), 
      data = data.frame(x = x, y = y)) 
}

pred_gaussian = function(x,y,mu){
  params = summary(fit_gaussian(x,y,mu,k = max(y)))$parameters[,"Estimate"]
  gaussian_fn(x,mu = mu, sigma = params[1], k = max(y))
}