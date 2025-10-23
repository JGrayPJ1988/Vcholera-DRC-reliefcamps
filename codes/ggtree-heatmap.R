##############################################################################
### By Juan Perez Jimenez #########################
### Date: 07-24-2024   ############################
### Molecular EPI #################################
###################################################

# Loading libraries for the analysis
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install("ggtree")

library(phylobase)
library(BiocManager)
library(ggtree)
library(ape)
library(ggplot2)
library(colorspace)
library(phytools)
library(treeio)
library(ggpubr)
library(gridExtra)
library(grid)
library(ggimage)
library(TDbook)
library(tidyverse)
library(ggnewscale)

getwd()

# Loading a BEAST tree
tree <- read.beast(file = paste0(getwd(),"/vc.drc.2025.onlycamps-rc-bs-399m.(mcc-mean).trees"))
str(tree)
get.fields(tree)

dataorigin <- read.table(pipe("pbpaste"), header = T, sep = "\t")

decimal2Date(max(dataorigin$date.dec))

# Loading meta-data 
dataorigin$serotype <- gsub(
  x = dataorigin$serotype, pattern = ' ',
  replacement = '')

mismatched_taxa <- setdiff(tree@phylo$tip.label, dataorigin$sample.id)
print(mismatched_taxa)
#tree_cleaned <- drop.tip(tree, mismatched_taxa)
#tree_cleaned = rename_taxa(tree_cleaned, dataorigin, sample.id, id.name)

dd <- subset(dataorigin, sample.id %in% tree@phylo$tip.label)
row.names(dd) <- dd$sample.id
dd$SequenceName <- factor(dd$sample.id, levels = tree@phylo$tip.label)
dd <- dd[order(dd$SequenceName),]
all.equal(as.character(dd$SequenceName), tree@phylo$tip.label)

aligned <- all.equal(as.character(dd$SequenceName), tree@phylo$tip.label)
print(aligned)

# checking the variables names for plotting
print(unique(dd$serotype))
print(unique(dd$source))
print(unique(dd$location))
print(unique(dd$cluster))

library(ggtree)
library(ggplot2)
library(ggnewscale)
library(treeio)
library(dplyr)

# Colors for metadata attributes
myColsSero <- c(
  "Ogawa"    = '#009999', 
  "Inaba"    = '#FF7856',
  "Hikojima" = '#99F8FF'
)

myColsSource <- c(
  'campsite' = '#D69054', 
  'env'      = '#8EC280',
  'ctc'      = '#5B3794'
)

myColsCluster <- c(
  'cluster-a' = '#FF9933', 
  'cluster-b' = '#8E063B',
  'cluster-c' = '#78A5A1',
  'cluster-d' = '#B0B0B0',
  'cluster-e' = '#AD9024',
  'env'       = '#8EC280',
  'ctc'       = '#5B3794'
)

# Join metadata
options(ignore.negative.edge = TRUE)
tree_with_data <- full_join(tree, dataorigin, by = c("label" = "sample.id"))

# Main tree plot
p0 <- ggtree(tree_with_data, mrsd = "2024-10-30", size = 0.6, aes(color = cluster)) +
  #geom_point(aes(shape = factor(source)), size = 2.5, stroke = 0.5) +  # Shape by source
  geom_point2(
    aes(subset = posterior >= 0.90),
    size = 1.3, stroke = 0.5, shape = 23,
    color = '#272727'
  ) +
  scale_color_manual(
    values = myColsCluster,
    labels = c("Group-5", "Group-3", "Group-4", "Group-2", "Group-1", "env", "ctc")  # <-- legend labels
  ) + 
  theme_tree2(legend.position = "none")

# Add new fill scale for gheatmap
GomaGGTree <- p0 + new_scale_fill()

# Add heatmap (assumes 'dd' has serotype information in column 2)
GomaGGTree2 <- gheatmap(GomaGGTree,
                        dd[, 2, drop = FALSE], 
                        width = 0.09, offset = 0.05,
                        colnames_angle = 35, colnames_offset_y = 223,
                        hjust = 0.1, font.size = 0) +
  scale_fill_manual(
    values = myColsSero,
    labels = c('Hikojima', 'Inaba', 'Ogawa'),  # Sorted by visual preference
    guide = guide_legend(override.aes = list(size = 5))
  ) +
  scale_x_continuous(breaks = seq(2020, 2024.5, 0.5)) +
  theme(
    legend.text = element_text(size = 15),
    legend.position = "left",
    legend.title = element_blank(),
    axis.text.x = element_text(size = 14, angle = 0, vjust = 0.5, face = "bold")
  )

print(GomaGGTree2)

# Save plot
ggsave(file = "tree-vc-drc-onlycamps-without-shape-4.pdf", 
       plot = GomaGGTree2, width = 12, height = 10, 
       units = "in", dpi = 300, limitsize = FALSE)




