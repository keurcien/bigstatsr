% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/biglasso.R
\name{big_spLogReg}
\alias{big_spLogReg}
\title{Sparse logistic regression}
\usage{
big_spLogReg(X, y01.train, ind.train = rows_along(X), covar.train = NULL,
  ...)
}
\arguments{
\item{X}{A \link[=FBM-class]{FBM}.}

\item{y01.train}{Vector of responses, corresponding to \code{ind.train}.
\strong{Must be only 0s and 1s.}}

\item{ind.train}{An optional vector of the row indices that are used,
for the training part. If not specified, all rows are used.
\strong{Don't use negative indices.}}

\item{covar.train}{Matrix of covariables to be added in each model to correct
for confounders (e.g. the scores of PCA), corresponding to \code{ind.train}.
Default is \code{NULL} and corresponds to only adding an intercept to each model.}

\item{...}{Arguments passed on to \code{COPY_biglasso}
\describe{
  \item{alpha}{The elastic-net mixing parameter that controls the relative
contribution from the lasso (l1) and the ridge (l2) penalty. The penalty is
defined as \deqn{ \alpha||\beta||_1 + (1-\alpha)/2||\beta||_2^2.}
\code{alpha = 1} is the lasso penalty and \code{alpha} in between \code{0}
(\code{1e-6}) and \code{1} is the elastic-net penalty.}
  \item{lambda.min}{The smallest value for lambda, as a fraction of
lambda.max. Default is \code{.001} if the number of observations is larger than
the number of covariates and \code{.01} otherwise.}
  \item{nlambda}{The number of lambda values. Default is \code{100}.}
  \item{lambda.log.scale}{Whether compute the grid values of lambda on log
scale (default) or linear scale.}
  \item{lambda}{A user-specified sequence of lambda values. By default, a
sequence of values of length \code{nlambda} is computed, equally spaced on
the log scale.}
  \item{eps}{Convergence threshold for inner coordinate descent.
The algorithm iterates until the maximum change in the objective after any
coefficient update is less than \code{eps} times the null deviance.
Default value is \code{1e-7}.}
  \item{max.iter}{Maximum number of iterations. Default is \code{1000}.}
  \item{dfmax}{Upper bound for the number of nonzero coefficients. Default is
no upper bound. However, for large data sets, computational burden may be
heavy for models with a large number of nonzero coefficients.}
  \item{penalty.factor}{A multiplicative factor for the penalty applied to
each coefficient. If supplied, \code{penalty.factor} must be a numeric
vector of length equal to sum of the number of columns of \code{X} and the
number of covariables (intercept excluded). The purpose of \code{penalty.factor}
is to apply differential penalization if some coefficients are thought to be
more likely than others to be in the model. Current package doesn't allow
unpenalized coefficients. That is \code{penalty.factor} cannot be 0.}
  \item{warn}{Return warning messages for failures to converge and model
saturation? Default is \code{TRUE}.}
  \item{verbose}{Whether to print out the start, the timing of each lambda
iteration and the end. Default is \code{FALSE}.}
}}
}
\value{
A named list with following variables:
\item{intercept}{A vector of intercepts, corresponding to each lambda.}
\item{beta}{The fitted matrix of coefficients, store in sparse matrix
representation. The number of rows is equal to the number of
coefficients, and the number of columns is equal to \code{nlambda}.}
\item{iter}{A vector of length \code{nlambda} containing the number of
iterations until convergence at each value of \code{lambda}.}
\item{lambda}{The sequence of regularization parameter values in the path.}
\item{penalty}{Penalty used. See the input parameter \code{alpha}.}
\item{family}{Either \code{"gaussian"} or \code{"binomial"} depending on the
function used.}
\item{alpha}{Input parameter.}
\item{loss}{A vector containing either the residual sum of squares
(for linear models) or negative log-likelihood (for logistic models)
of the fitted model at each value of \code{lambda}.}
\item{penalty.factor}{Input parameter.}
\item{n}{The number of observations used in the model fitting. It's equal
to \code{length(row.idx)}.}
\item{p}{The number of dimensions (including covariables,
but not the intercept).}
\item{center}{The sample mean vector of the variables, i.e., column mean
of the sub-matrix of \code{X} used for model fitting.}
\item{scale}{The sample standard deviation of the variables, i.e.,
column standard deviation of the sub-matrix of \code{X} used for model
fitting.}
\item{y}{The response vector used in the model fitting. Depending on
\code{row.idx}, it could be a subset of the raw input of the response vector
y.}
\item{col.idx}{The indices of features that have 'scale' value greater
than \code{1e-6}. Features with 'scale' less than 1e-6 are removed from
model fitting.}
\item{rejections}{The number of features rejected at each value of
\code{lambda}.}
}
\description{
Sparse logistic regression
}
\details{
\strong{This is a modified version of one function of
\href{https://github.com/YaohuiZeng/biglasso}{package biglasso}}.
It adds the possibility to train models with covariables and use many
types of \code{FBM} (not only \code{double} ones).
Yet, it only corresponds to \code{screen = "SSR"} (Sequential Strong Rules).
}
\examples{
set.seed(1)

# simulating some data
N <- 73
M <- 430
X <- FBM(N, M, init = rnorm(N * M, sd = 5), type = "integer")
y <- sample(0:1, size = N, replace = TRUE)
covar <- matrix(rnorm(N * 3), N)

# error, only handle `double` `big.matrix` objects
X2 <- bigmemory::as.big.matrix(X[], type = "integer", shared = FALSE)
\dontrun{biglasso::biglasso(X2, y, family = "binomial")}

# OK here
test2 <- big_spLogReg(X, y)
str(test2)

# how to use covariables?
X2 <- bigmemory::as.big.matrix(cbind(X[,], covar), type = "double",
                               shared = FALSE)
test <- biglasso::biglasso(X2, y, family = "binomial", lambda.min = 0.01,
                           alpha = 0.5, penalty = "enet")
test2 <- big_spLogReg(X, y, covar.train = covar, alpha = 0.5)
# verification
all.equal(test2$lambda, test$lambda)
all.equal(test2$beta@x, test$beta[-1, ]@x)
all.equal(test2$intercept, test$beta[1, ])
}
\references{
Tibshirani, R., Bien, J., Friedman, J., Hastie, T.,
Simon, N., Taylor, J. and Tibshirani, R. J. (2012),
Strong rules for discarding predictors in lasso-type problems.
Journal of the Royal Statistical Society:
Series B (Statistical Methodology), 74: 245–266.
\url{http://dx.doi.org/10.1111/j.1467-9868.2011.01004.x}.

Zeng, Y., and Breheny, P. (2016). The biglasso Package: A Memory- and
Computation-Efficient Solver for Lasso Model Fitting with Big Data in R.
arXiv preprint arXiv:1701.05936. \url{https://arxiv.org/abs/1701.05936}.
}
\seealso{
\link[glmnet:glmnet]{glmnet} \link[biglasso:biglasso]{biglasso}
}
