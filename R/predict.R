################################################################################

#' Predict method
#'
#' Predict method for class `big_CMSA`.
#'
#' @param object Object of class `big_CMSA`.
#' @inheritParams bigstatsr-package
#' @param ... Not used.
#'
#' @return A vector of prediction scores, corresponding to `ind.row`.
#'
#' @export
#' @importFrom stats predict
#'
#' @seealso [big_CMSA]
#'
predict.big_CMSA <- function(object, X,
                             ind.row = rows_along(X),
                             covar.row = NULL,
                             ...) {

  check_args()

  ind.col <- which(object[cols_along(X)] != 0)
  stopifnot(length(ind.col) > 0)

  scores <- big_prodVec(X, object[ind.col],
                        ind.row = ind.row,
                        ind.col = ind.col)

  if (!is.null(covar.row)) {

    assert_lengths(ind.row, rows_along(covar.row))

    ncov <- ncol(covar.row)

    scores <- scores + as.numeric(covar.row %*% tail(object, ncov))
  }

  names(scores) <- ind.row
  scores
}

################################################################################

#' Predict method
#'
#' Predict method for class `big_sp`.
#'
#' @param object Object of class `big_sp`.
#' @inheritParams bigstatsr-package
#' @param ... Not used.
#'
#' @return A matrix of scores, with rows corresponding to `ind.row`
#' and columns corresponding to `lambda`.
#'
#' @export
#' @import Matrix
#' @importFrom stats predict
#'
#' @seealso [big_spLinReg], [big_spLogReg] and [big_spSVM].
#'
#' @example examples/example-predict.R
#'
predict.big_sp <- function(object, X,
                           ind.row = rows_along(X),
                           covar.row = NULL,
                           block.size = block_size(nrow(X)),
                           ...) {

  check_args()

  betas <- object$beta

  if (is.null(covar.row)) {

    scores <- big_prodMat(X, betas,
                          ind.row = ind.row,
                          block.size = block.size)

  } else {

    assert_lengths(ind.row, rows_along(covar.row))

    ind.X <- cols_along(X)
    scores <- big_prodMat(X, betas[ind.X, ],
                          ind.row = ind.row,
                          block.size = block.size) +
      covar.row %*% betas[-ind.X, ]

  }

  rownames(scores) <- ind.row
  as.matrix(sweep(scores, 2, object$intercept, "+"))
}

################################################################################

#' Predict method
#'
#' Predict method for class `mhtest`.
#'
#' @param object An object of class `mhtest` from you get the probability
#'   function with possibly pre-transformation of scores.
#' @param scores Raw scores (before transformation) that you want to transform
#'   to p-values.
#' @param log10 Are p-values returned on the `log10` scale? Default is `TRUE`.
#' @param ... Not used.
#'
#' @return Vector of **`log10(p-values)`** associated with `scores` and `object`.
#'
#' @export
#' @importFrom stats predict
#' @importFrom magrittr %>%
#'
#' @seealso [big_univLinReg] and [big_univLogReg].
#'
predict.mhtest <- function(object, scores = object$score, log10 = TRUE, ...) {

  lpval <- scores %>%
    attr(object, "transfo")() %>%
    attr(object, "predict")()

  `if`(log10, lpval, 10^lpval)
}


################################################################################

#' Scores of PCA
#'
#' Get the scores of PCA associated with an svd decomposition (class `big_SVD`).
#'
#' @inheritParams bigstatsr-package
#' @param object A list returned by `big_SVD` or `big_randomSVD`.
#' @param ... Not used.
#'
#' @export
#'
#' @return A matrix of size \eqn{n \times K} where `n` is the number of samples
#' corresponding to indices in `ind.row` and K the number of PCs
#' computed in `object`. If `X` is not specified, this just returns
#' the scores of the training set of `object`.
#'
#' @example examples/example-SVD.R
#'
#' @seealso [predict][stats::prcomp] [big_SVD] [big_randomSVD]
#'
predict.big_SVD <- function(object, X = NULL,
                            ind.row = rows_along(X),
                            ind.col = cols_along(X),
                            block.size = block_size(nrow(X)),
                            ...) {

  if (is.null(X)) {
    k <- length(object$d)
    object$u %*% diag(object$d, k, k)
  } else {
    check_args()

    # Multiplication with clever scaling (see vignettes)
    v2 <- object$v / object$scale
    tmp <- big_prodMat(X, v2,
                       ind.row = ind.row,
                       ind.col = ind.col,
                       block.size = block.size)
    sweep(tmp, 2, crossprod(object$center, v2), "-")
  }
}

################################################################################
