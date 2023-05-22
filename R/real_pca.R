load("data/sec4_real_dats.RData")

source("R/setup.R")
source("R/help_funs.R")


pca_embs <- parallel::mclapply(
  l_dats,
  function(dat) prcomp(dat$dat_X),
  mc.cores = 6
)

pca_dbs <- parallel::mcmapply(
  function(pca, dat) {
    eps <- l_dats
    cluster_res(pca$x[, 1:3], eps = dat$eps_range, lbls = dat$dat_lbls)
  },
  pca = pca_embs,
  dat = l_dats,
  SIMPLIFY = FALSE,
  mc.cores = 6
)

dt_res_pca <- cbind(
  Data = unlist(
    lapply(
      names(pca_dbs),
      function(nam) rep(nam, nrow(pca_dbs[[nam]])))
  ),
  Method = "PCA+DBSCAN",
  eps = unlist(
    lapply(
      l_dats,
      function(dat) dat$eps_range)
  ),
  as.data.table(do.call(rbind, pca_dbs))
)

dt_res_pca$k <- NA

nic_names <- c("iris" = "Iris", "wine" = "Wine", "coil" = "COIL",
               "pendigits" = "Pendigits", "mnist" = "MNIST", "fmnist" = "FMNIST-10")

dt_res_pca$Data <- factor(
  dt_res_pca$Data,
  labels = nic_names[levels(factor(dt_res_pca$Data))]
)

load("data/results/res_real_full.RData")

dt_res_pca_long <- melt(
  dt_res_pca,
  id.vars = c("Data", "Method", "eps", "k"),
  measure.vars = c("ARI", "NMI"),
  variable.name = "Measure",
  value.name = "Performance"
)

load("data/results/res_real_full.RData")

dt_res_real_long <- melt(
  dt_res_real_full,
  id.vars = c("Data", "Method", "eps", "k"),
  measure.vars = c("ARI", "NMI"),
  variable.name = "Measure",
  value.name = "Performance"
)

dt_res <- rbind(dt_res_real_long, dt_res_pca_long)
dt_res <- dt_res[Data != "FMNIST-5"]

plt_dir <-
  ggplot(dt_res[Method == "DBSCAN" , ]) +
  geom_line(aes(x = eps, y = Performance, color = Measure, lty = Measure)) +
  facet_wrap(~ Data, scales = "free_x", ncol = 1) +
  xlab(eps_tex) +
  ylim(0, 1) +
  ggtitle("DBSCAN")
plt_emb <-
  ggplot(dt_res[k == 10, ]) +
  geom_line(aes(x = eps, y = Performance, color = Measure, lty = Measure)) +
  facet_wrap(~ Data, scales = "free_x", ncol = 1) +
  xlab(eps_tex) +
  ylim(0, 1) +
  ggtitle("UMAP+DBSCAN")
plt_pca <-
  ggplot(dt_res[Method == "PCA+DBSCAN", ]) +
  geom_line(aes(x = eps, y = Performance, color = Measure, lty = Measure)) +
  facet_wrap(~ Data, scales = "free_x", ncol = 1) +
  xlab(eps_tex) +
  ylim(0, 1) +
  ggtitle("PCA+DBSCAN")

plt_dir + plt_pca + plt_emb + plot_layout(guides = "collect") & theme(legend.position = "bottom")

