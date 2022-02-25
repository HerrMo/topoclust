# setup

library(seriation)
library(dbscan)
library(mclust) # adjusted rand index
library(aricode) # Normalized mutual information
library(mlbench) # spirals data
library(ggplot2)
library(latex2exp)
library(MASS)
library(uniformly)
library(patchwork)
library(data.table)
library(ggplot2)
library(RColorBrewer)
library(parallel)

eps_tex <- TeX("$\\epsilon$")

theme <- theme_bw(base_size = 12,
                  base_line_size = 0.75)
theme_set(theme)

lyt <- list(
  theme(legend.position = "none"),
  scale_colour_manual(values = c(scales::alpha("red", .15),
                                 scales::alpha("green", .15),
                                 "blue",
                                 scales::alpha("black", .4)))
)
emb_lyt <- c(list(xlab("UMAP 1"), ylab("UMAP 2")), lyt)
dat_lyt <- c(list(xlab("X1"), ylab("X2")), lyt)
