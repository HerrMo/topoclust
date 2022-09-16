# cluster_res
#
# Computes dbscan cluster results (ARI and NMI) for a set of epsilon values
# eps_range: the epslion values to compute over
# dat: the data (as dist object)

cluster_res <- function(dat, eps_range, lbls, ...) {
  res <-
    vapply(eps_range,
           function(eps) performance(
             dbscan::dbscan(dat, eps = eps)$cluster, # minPts = 5 (default)
             lbls),
           numeric(2))
  t(res)
}

performance <- function(x, y, ...) {
  c(
    ARI = mclust::adjustedRandIndex(x, y),
    NMI = aricode::NMI(x, y, ...) # maximum normalization default
  )
}


# Loads MNIST data, see: https://gist.github.com/sboysel/3fed0a36a5b231278089
load_mnist <- function() {
  load_image_file <- function(filename) {
    ret = list()
    f = file(filename,'rb')
    readBin(f,'integer',n=1,size=4,endian='big')
    ret$n = readBin(f,'integer',n=1,size=4,endian='big')
    nrow = readBin(f,'integer',n=1,size=4,endian='big')
    ncol = readBin(f,'integer',n=1,size=4,endian='big')
    x = readBin(f,'integer',n=ret$n*nrow*ncol,size=1,signed=F)
    ret$x = matrix(x, ncol=nrow*ncol, byrow=T)
    close(f)
    ret
  }
  load_label_file <- function(filename) {
    f = file(filename,'rb')
    readBin(f,'integer',n=1,size=4,endian='big')
    n = readBin(f,'integer',n=1,size=4,endian='big')
    y = readBin(f,'integer',n=n,size=1,signed=F)
    close(f)
    y
  }
  train <<- load_image_file('data/datasets/train-images-idx3-ubyte')
  test <<- load_image_file('data/datasets/t10k-images-idx3-ubyte')

  train$y <<- load_label_file('data/datasets/train-labels-idx1-ubyte')
  test$y <<- load_label_file('data/datasets/t10k-labels-idx1-ubyte')
}

# function to plot embeddings
plot_emb <- function(embedding, ...) {
  UseMethod("plot_emb")
}

# default method for embedding data in 2d matrix format
plot_emb.default <- function(pts, color = NULL, size = 1, ...) {

  dat <- data.frame(dim1 = pts[, 1],
                    dim2 = pts[, 2],
                    color = 1:nrow(pts))

  if (!is.null(color)) dat$color <- color

  p <- ggplot(dat) +
    geom_point(aes(x = dim1,
                   y = dim2,
                   colour = color),
               size = size) +
    theme(legend.position = "Non") +
    ggtitle(label = "2d-embedding")
  p
}

# for embeddings coordinates in matrix format
plot_emb.matrix <- function(embedding, color = NULL, labels_off = TRUE, labels = NULL, size = 1, ...) {
  # TODO argument checking (min 2-d data, etc)

  pts <- extract_points(embedding, 2)
  p <- plot_emb.default(pts, color = color, labels = labels, size = size, ...)
  if (!labels_off) p <- if (is.null(labels)) {
    p + ggrepel::geom_text_repel(aes(x = dim1, y = dim2, label = 1:nrow(pts)), size = label_size)
  } else {
    p + ggrepel::geom_text_repel(aes(x = dim1, y = dim2, label = labels), size = label_size)
  }
  p
}

# for objects of class embedding
plot_emb.embedding <- function(embedding, color = NULL, labels = FALSE, size = 1) {
  # TODO argument checking (min 2-d data, etc)

  emb <- embedding$emb
  pts <- extract_points(emb, 2)
  p <- plot_emb.default(pts, color = color, labels = labels, size = size, ...)
  if (labels) p <- p + ggrepel::geom_text_repel(aes(x = dim1, y = dim2, label = 1:nrow(pts)))
  p
}

plot_emb.umap <- function(embedding, color = NULL, labels_off = TRUE, labels = NULL, size = 1, ...) {
  # TODO argument checking (min 2-d data, etc)

  pts <- extract_points(embedding, 2)
  p <- plot_emb.default(pts, color = color, labels = labels, size = size, ...)
  if (!labels_off) p <- if (is.null(labels)) {
    p + ggrepel::geom_text_repel(aes(x = dim1, y = dim2, label = 1:nrow(pts)))
  } else {
    p + ggrepel::geom_text_repel(aes(x = dim1, y = dim2, label = labels))
  }
  p
}

# help fun S3 class to extract embedding coordinates
extract_points <- function(x, ...) {
  UseMethod("extract_points")
}

# S3 method for umap
extract_points.umap <- function(embedding, ndim = dim(embedding$layout)[2]) {
  embedding$layout[, 1:ndim, drop = FALSE]
}

# S3 method for matrix output, e.g. mds
extract_points.matrix <- function(embedding, ndim = dim(embedding)[2]) {
  embedding[, 1:ndim, drop = FALSE]
}



