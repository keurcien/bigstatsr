set.seed(1)

big_spSVM <- bigstatsr:::big_spSVM

# simulating some data
N <- 73
M <- 430
X <- FBM(N, M, init = rnorm(N * M, sd = 5))
y <- sample(0:1, size = N, replace = TRUE)
y.factor <- factor(y, levels = c(1, 0))
covar <- matrix(rnorm(N * 3), N)

# error, only handle standard R matrices
\dontrun{test <- sparseSVM::sparseSVM(X, y)}

# OK here
test2 <- big_spSVM(X, y)
str(test2)

# how to use covariables?
X2 <- cbind(X[], covar)
test <- sparseSVM::sparseSVM(X2, y.factor, alpha = 0.5)
test2 <- big_spSVM(X, y, covar.train = covar, alpha = 0.5)
# verification
all.equal(test2$lambda, test$lambda)
all.equal(as.matrix(test2$beta), test$weights[-1, ], check.attributes = FALSE)
all.equal(test2$intercept, test$weights[1, ])
