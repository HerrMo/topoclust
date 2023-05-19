rep_fun <- function(setting, opt_vals, reps = REPS, seed = TRUE, exp_settings = exp_settings) {

  # setting: name of setting
  # opt_vals: data.table "eps_opt_vals" - optimal epsilon values and other stuff
  # reps: number of replications
  # seed: set seed for each replication to number of replication

  set <- setting ## iterate over

  l_res <- vector(mode = "list", length = reps)
  for (rep in seq_len(reps)) {
    if (seed) set.seed(rep)

    ### GENERATE DATA SETS

    rep_dat <- do.call(cluster_dat, exp_settings[[set]])

    # add irrelevant features to create setting U_1003
    if (set == "u1003") rep_dat <- cbind(rep_dat, matrix(runif(1500000), ncol = 1000))

    ## RAW DATA DISTS
    # precomputing distances reduces computation time in dbscan if p is large
    rep_dist <- dist(rep_dat)

    # Random states parameter sampled as follows
    # set.seed(113)
    # random_states <- sample(1:10000000, 1)

    ## UMAP EMBEDDING DISTS
    rep_emb <- umap::umap(
      as.matrix(rep_dist),
      random_state = 9740922,
      n_neighbors = 5,
      n_components = 2,
      input = "dist"
    )

    rep_emb_dists <- dist(rep_emb$layout)

    rep_dists <- list("DBSCAN" = rep_dist, "UMAP+DBSCAN" = rep_emb_dists)


    ### RUN DBSCAN
    # - on raw data and umap embs
    # - for optimal eps vals (w.r.t ARI) +-0.2 (s. eps_rng)
    # - return ARI and NMI

    ## Prepare exp setup
    # - select optimal values for considered setting (1)
    # - replicate each eps value (1)
    # - generate eps vals +-0.2 (2)

    # (1)
    temp_eps <- eps_opt_vals[setting == set, .(method, eps)][rep(c(1, 2), each = 3)]

    # (2)
    temp_eps <- temp_eps[, .(method, eps = eps + rep(eps_rng, 2))]

    ## Compute clustering results
    # - compute DBSCAN clustering for different epsilon values
    # - on raw data and umap embeddings
    # - Return ARI and NMI

    dt_res_rep <- vector(mode = "list", length = nrow(temp_eps))

    for (i in seq_len(nrow(temp_eps))) {
      meth <- temp_eps[i, method]
      eps <- temp_eps[i, eps]
      dat <- rep_dists[[meth]]
      dt_res_rep[[i]] <- round(as.data.table(cluster_res(dat = dat, eps = eps, lbls = lbls)), 3)
    }
    l_res[[rep]] <- cbind(set, rep, temp_eps, rbindlist(dt_res_rep))
  }

  rbindlist(l_res)
}

