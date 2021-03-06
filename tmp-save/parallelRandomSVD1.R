ParallelRandomSVD1 <- function(X, fun.scaling,
                               ind.train,
                               block.size,
                               K, I,
                               use.Eigen,
                               backingpath,
                               ncores) {
  # parameters
  L <- K + 12
  n <- length(ind.train)
  m <- ncol(X)
  I <- I + 1
  stopifnot((m - K) >= (I * L))

  TIME <- 0.01
  tmp.lock.name <- "mutex"
  tmp.lock.names <- paste(tmp.lock.name, Sys.getpid(), 1:3, sep = '-')
  ifelse(file.exists(tmp.lock.names), FALSE,
         file.create(tmp.lock.names))

  # shared big.matrices
  G <- big.matrix(m, L, type = "double", shared = TRUE)
  G[] <- stats::rnorm(m * L) # G0
  R <- big.matrix(n, L * I, type = "double", shared = TRUE, init = 0)
  Q <- big.matrix(n, L * I, type = "double", shared = TRUE)
  T.t <- big.matrix(m, L * I, type = "double", shared = TRUE)
  remains <- big.matrix(3, I - 1, type = "integer",
                        shared = TRUE, init = ncores)

  # descriptors
  X.desc <- describe(X)
  G.desc <- describe(G)
  R.desc <- describe(R)
  Q.desc <- describe(Q)
  T.t.desc <- describe(T.t)
  r.desc <- describe(remains)


  intervals <- CutBySize(m, nb = ncores)

  if (is.seq <- (ncores == 1)) {
    registerDoSEQ()
  } else {
    cl <- parallel::makeCluster(ncores)
    doParallel::registerDoParallel(cl)
  }
  scaling <- foreach(ic = seq_len(ncores), .combine = 'cbind') %dopar% {
    lims <- intervals[ic, ]

    # get big.matrices
    X.part <- sub.big.matrix(X.desc,
                             firstCol = lims[1],
                             lastCol = lims[2],
                             backingpath = backingpath)

    # https://www.r-bloggers.com/too-much-parallelism-is-as-bad/
    multi <- (!is.seq) && detect_MRO()
    if (multi) nthreads.save <- RevoUtilsMath::setMKLthreads(1)

    # scaling
    means_sds <- fun.scaling(X.part, ind.train)
    means <- means_sds$mean
    sds <- means_sds$sd
    rm(means_sds)

    # parameters
    m.part <- ncol(X.part)
    intervals <- CutBySize(m.part, block.size)
    nb.block <- nrow(intervals)

    G.part <- sub.big.matrix(G.desc, firstRow = lims[1], lastRow = lims[2])
    tmp.R <- matrix(0, n, L)
    for (j in 1:nb.block) {
      ind <- seq2(intervals[j, ])
      tmp <- scaling(X.part[ind.train, ind], means[ind], sds[ind])

      tmp.R <- incrMat(tmp.R, mult(tmp, G.part[ind, ], use.Eigen))
    }

    # increment R_0, safely
    remains <- attach.big.matrix(r.desc)
    R.part <- sub.big.matrix(R.desc, firstCol = 1, lastCol = L)
    file.lock1 <- flock::lock(tmp.lock.names[1])
    incrG(R.part@address, tmp.R, n, L, 1)
    remains[1, 1] <- remains[1, 1] - 1L
    flock::unlock(file.lock1)
    # wait for others at barrier
    while (remains[1, 1] > 0) Sys.sleep(TIME)

    # computation of R
    for (i in 1:(I - 1)) {
      tmp.R[] <- 0
      for (j in 1:nb.block) {
        ind <- seq2(intervals[j, ])
        tmp <- scaling(X.part[ind.train, ind], means[ind], sds[ind])

        tmp.R <- incrMat(tmp.R, mult(tmp, cross(tmp, R.part[,], use.Eigen), use.Eigen))
      }

      # increment R_i, safely
      R.part <- sub.big.matrix(R.desc, firstCol = 1 + i*L, lastCol = (i+1)*L)
      file.lock2 <- flock::lock(tmp.lock.names[2])
      incrG(R.part@address, tmp.R, n, L, 2*m)
      remains[2, i] <- remains[2, i] - 1L
      flock::unlock(file.lock2)
      # wait for others at barrier
      while (remains[2, i] > 0) Sys.sleep(TIME)
    }

    # compute svd(R) once
    Q <- attach.big.matrix(Q.desc)
    file.lock3 <- flock::lock(tmp.lock.names[3])
    if (remains[3, 1] == 1) {
      R <- attach.big.matrix(R.desc)
      if (multi) RevoUtilsMath::setMKLthreads(nthreads.save)
      Q[] <- svd(R[,], nv = 0)$u
      if (multi) nthreads.save <- RevoUtilsMath::setMKLthreads(1)
    }
    remains[3, 1] <- remains[3, 1] - 1L
    flock::unlock(file.lock3)
    # wait for others at barrier
    while (remains[3, 1] > 0) Sys.sleep(TIME)

    # compute transpose(T)
    T.t.part <- sub.big.matrix(T.t.desc, firstRow = lims[1], lastRow = lims[2])
    for (j in 1:nb.block) {
      ind <- seq2(intervals[j, ])
      tmp <- scaling(X.part[ind.train, ind], means[ind], sds[ind])

      T.t.part[ind, ] <- cross(tmp, Q[,], use.Eigen)
    }

    if (multi) RevoUtilsMath::setMKLthreads(nthreads.save)

    rbind(means, sds)
  }
  if (!is.seq) parallel::stopCluster(cl)

  # delete temporary lock files
  unlink(tmp.lock.names)

  T.svd <- svd(T.t[,], nu = K, nv = K)

  list(d = T.svd$d[1:K], u = Q[,] %*% T.svd$v, v = T.svd$u,
       means = scaling[1, ], sds = scaling[2, ])
}
