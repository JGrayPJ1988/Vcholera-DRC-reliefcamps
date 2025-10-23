library(tidyverse)
library(ggplot2)

getwd()

dist_matrix <- read.csv("MEGA-result.pairwise.distance.csv", row.names = 1,  check.names = FALSE)

metadata <- read.delim("traits.beast.discrete.txt", stringsAsFactors = FALSE, header = T)

dist_obj <- as.dist(as.matrix(dist_matrix))

mds <- cmdscale(as.dist(dist_obj), k = 2, eig = TRUE)
pca_df <- as.data.frame(mds$points)
colnames(pca_df) <- c("PC1", "PC2")
pca_df$Sample <- rownames(pca_df)

pca_df <- left_join(pca_df, metadata, by = c("Sample" = "name"))  
#pca_df <- pca_df %>%
  #filter(!cluster %in% c("ctc", "env"))

myColsSource <- c(
  'env' = '#8EC280',
  'ctc' = '#5B3794',
  'campsite' = 'black'
)

# Define colors only for real clusters (exclude 'env' and 'ctc')
myColsCluster <- c(
  'Group-5' = '#FF9933',
  'Group-4' = '#78A5A1',
  'Group-3' = '#8E063B',
  'Group-2' = '#B0B0B0',
  'Group-1' = '#AD9024',
  'ctc' = '#5B3794',
  'env' = '#8EC280'
)

# Define shape values for sources
# shapeVals <- c(
#   'env' = 15,       # square
#   'ctc' = 17,       # triangle
#   'campsite' = 16   # circle
# )

# Ensure group column follows the same order as myColsCluster
pca_df$group <- factor(pca_df$group, levels = names(myColsCluster))

# Then plot
pca <- ggplot(pca_df, aes(x = PC1, y = PC2)) +
  geom_point(aes(color = group),
             size = 4, alpha = 0.6) +
  scale_color_manual(values = myColsCluster, breaks = names(myColsCluster)) +
  theme_minimal() +
  labs(x = "PC1", y = "PC2") +
  theme(
    legend.position = "top",
    legend.direction = "horizontal"
  ) +
  #guides(color = guide_legend(title = NULL))
  guides(color = guide_legend(title = NULL, nrow=1))

pca


ggsave(file = "PCA-pairwise-plot-final.pdf", 
       plot = pca, width = 6.3, height = 4, 
       units = "in", dpi = 300, limitsize = FALSE)

library(ape)
pc <- pcoa(dist_obj, correction = "cailliez")  # or "lingoes" or "none"
eig <- pc$values$Eigenvalues
prop <- eig / sum(eig[eig > 0])
pc1_lab <- sprintf("PC1 (%.1f%%)", 100 * prop[1])
pc2_lab <- sprintf("PC2 (%.1f%%)", 100 * prop[2])

pcoa_df <- as.data.frame(pc$vectors[, 1:2])
colnames(pcoa_df) <- c("PC1","PC2")
pcoa_df$Sample <- rownames(pcoa_df)
pcoa_df <- dplyr::left_join(pcoa_df, metadata, by = c("Sample" = "name"))
pcoa_df$group <- factor(pcoa_df$group, levels = names(myColsCluster))

pca_2 <- ggplot(pcoa_df, aes(PC1, PC2, color = group)) +
  geom_point(size = 4, alpha = 0.6) +
  scale_color_manual(values = myColsCluster, breaks = names(myColsCluster)) +
  coord_equal() +
  theme_minimal() +
  labs(x = pc1_lab, y = pc2_lab) +
  theme(legend.position = "top", legend.direction = "horizontal") +
  guides(color = guide_legend(title = NULL, nrow = 1))

pca_2

ggsave(file = "PCA-pairwise-plot-final.pdf", 
       plot = pca_2, width = 8.3, height = 5, 
       units = "in", dpi = 300, limitsize = FALSE)



