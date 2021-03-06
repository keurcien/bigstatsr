/******************************************************************************/

#include <bigstatsr/BMAcc.h>
#include <bigstatsr/utils.h>
#include <Rcpp.h>

using namespace Rcpp;
using std::size_t;

/******************************************************************************/

template <typename T, int RTYPE>
Vector<RTYPE> extractVec(VecBMAcc<T> macc) {

  size_t K = macc.nelem();

  Vector<RTYPE> res(K);

  for (size_t k = 0; k < K; k++)
    res[k] = macc[k];

  return res;
}

#define EXTRACT_VEC(BM_TYPE, RTYPE) {                                          \
  return extractVec<BM_TYPE, RTYPE>(VecBMAcc<BM_TYPE>(xpBM, elemInd - 1));     \
}

// [[Rcpp::export]]
RObject extractVec(RObject xpbm,
                   const NumericVector& elemInd) {

  XPtr<FBM> xpBM(xpbm);

  switch(xpBM->matrix_type()) {
  case 1:
    EXTRACT_VEC(unsigned char,  RAWSXP)
  case 2:
    EXTRACT_VEC(unsigned short, INTSXP)
  case 4:
    EXTRACT_VEC(int,            INTSXP)
  case 8:
    EXTRACT_VEC(double,         REALSXP)
  default:
    throw Rcpp::exception(ERROR_TYPE);
  }
}

/******************************************************************************/

template <typename T, int RTYPE>
Vector<RTYPE> extractMat(SubBMAcc<T> macc) {

  size_t n = macc.nrow();
  size_t m = macc.ncol();

  Matrix<RTYPE> res(n, m);

  for (size_t j = 0; j < m; j++)
    for (size_t i = 0; i < n; i++)
      res(i, j) = macc(i, j);

  return res;
}

#define EXTRACT_MAT(BM_TYPE, RTYPE) {                                          \
  return extractMat<BM_TYPE, RTYPE>(SubBMAcc<BM_TYPE>(xpBM, rowInd - 1,        \
                                                      colInd - 1));            \
}

// [[Rcpp::export]]
RObject extractMat(RObject xpbm,
                   const IntegerVector& rowInd,
                   const IntegerVector& colInd) {

  XPtr<FBM> xpBM(xpbm);

  switch(xpBM->matrix_type()) {
  case 1:
    EXTRACT_MAT(unsigned char,  RAWSXP)
  case 2:
    EXTRACT_MAT(unsigned short, INTSXP)
  case 4:
    EXTRACT_MAT(int,            INTSXP)
  case 8:
    EXTRACT_MAT(double,         REALSXP)
  default:
    throw Rcpp::exception(ERROR_TYPE);
  }
}

/******************************************************************************/
