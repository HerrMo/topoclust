source("R/setup.R")
source("R/help_funs.R")

# DBSCAN
eps_range_fcps <- seq(0.01, 20, by = 0.01)


## data

datsets <- c("Hepta", "Lsun", "Tetra", "Chainlink", "Atom",
             "EngyTime", "Target", "TwoDiamonds", "WingNut", "GolfBall")

exp_fcps_dats <- sapply(
  datsets,
  function(dat) {
    d <- read.table(paste0("data/FCPS/01FCPSdata/", dat, ".txt"))
    d <- d[, -1] # remove useless index column
    names(d) <- paste0("X", seq_len(ncol(d)))
    d
  }
)

exp_fcps_pca <- lapply(
  exp_fcps_dats,
  function(dat) princomp(x = dat)
)

cores_to_use <- 5
exp_fcps_res <- parallel::mcmapply(
  function(dat, lbls) cluster_res(
    dat = dat,
    eps_range = eps_range_fcps,
    lbls = lbls_fcps[[lbls]]
  ),
  dat = c(exp_fcps_dats, lapply(exp_fcps_pca, function(emb) emb$scores[, 1:2])),
  lbls = rep(datsets, 2),
  SIMPLIFY = FALSE,
  mc.cores = cores_to_use
)

eps_threshold <- 0

dt_fcps_res[, .(maxARI = round(max(ARI), 2),
                maxNMI = round(max(NMI), 2)),
            by = c("data", "method")]
dt_fcps_res[, .(eps_range_gr = range(eps[ARI > eps_threshold])),
            by = c("data", "method")]
