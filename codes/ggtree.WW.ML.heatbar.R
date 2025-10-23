# Loading libraries for the analysis
#if (!require("BiocManager", quietly = TRUE))
#  install.packages("BiocManager")
# BiocManager::install("ggtree")
require(BiocManager)
library(phylobase)
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
library(lubridate)
library(TDbook)
library(tidyverse)
library(ggnewscale)

getwd()

treeo <- read.nexus(file = paste0(getwd(),"/timetree.nexus"))

treeo1 <- drop.tip(treeo, tip= c("1_033_I_S1_CRO_Ogawa_S17",
                                 "2_018_I_F4_CRO_Ogawa_S18",
                                 "1_063_I_F3_CRO_Ogawa_S14",
                                 "1_040_I_S1_CRO_Inaba_S15",
                                 "1_042_I_F4_CRO_Ogawa_S13",
                                 "1_012_I_Mo_CRO_Inaba_S16",
                                 "Reference"))

data <- read.table(pipe("pbpaste"), header = T, sep = "\t")      

decimal2Date(max(data$dates))

library(countrycode)
data$country <- countrycode(data$country, "country.name", "iso3c")

treeo1$tip.label <- trimws(treeo1$tip.label)
data$name        <- trimws(data$name)

# Adding tip labels to tree
all_labels_match <- all(treeo1$tip.label %in% data$name)
missing_labels <- setdiff(treeo1$tip.label, data$name)
missing_labels <- setdiff(data$name, treeo1$tip.label)
print(missing_labels)

dd <- subset(data, name %in% treeo1$tip.label)
row.names(dd) <- dd$name
dd$SequenceName <- factor(dd$name, levels = treeo1$tip.label)
dd <- dd[order(dd$SequenceName),]
all.equal(as.character(dd$SequenceName), treeo1$tip.label)

aligned <- all.equal(as.character(dd$SequenceName), treeo1$tip.label)
print(aligned)

print(unique(dd$Continent))
as.factor(dd$Transmission.Event)
print(unique(dd$Transmission.Event))
print(unique(dd$source))

# making colors for metadata attributes
myColsContinent <- c(
  "Asia"= "#A05D68",  # muted coral red
  "Oceania"= "#A58FC0",   # soft lavender purple
  "Africa"= "#CDAE70",  # soft golden brown
  "Africa-DRC-this-study"= "#FC7D69",  # soft golden brown
  "Europe"= "#6CA6CD",  # soft steel blue
  "South_America"= "#4F9D69",  # warm muted orange
  "Central_America"= "#56BD96",  # light olive green
  "North_America"= "#B3E0A6"  # gentle green
  
)

myColsT_lineage <- c(
  "No data" = "white",
  "sporadic/local outbreak"  = "#BD3977",
  "T2"  = "#006E37",
  "T12"  = "#A24E27",  # deep slate blue
  "T11"  = "#B9723B",
  "T10" = "#376CC3",
  "T9"  = "#C38347",
  "T8"  = "#CC9354",
  "T7"  = "#D5A362",
  "T6"  = "#DFBA79",
  "T5"  = "#E6C889",
  "T4"  = "#EDDCA3",
  "T3" = "#F1E7B5",
  "T1" = "#F3F0CA"
  ) 

options(ignore.negative.edge=TRUE)
treeo1 <- reroot(treeo1, node = which(treeo$tip.label == "Asia|Bangladesh_N16961|SRR5057122|1975"))

p0 <- ggtree(treeo1, mrsd = "2024-07-01", size = 0.5) %<+% dd +
  geom_tree(linewidth = 0.5, color = "#C3C3C3") + 
  geom_tippoint(aes(color = Continent), size = 1.8, alpha = 0.95) +
  scale_color_manual(values = myColsContinent, na.value = "grey75", name = "Continent")

print(p0)

years <- seq(
  floor(min(p0$data$dates, na.rm = TRUE)),
  ceiling(max(p0$data$dates, na.rm = TRUE)),
  by = 4)

p1 <- gheatmap(p0,
               dd[, 8, drop = FALSE],
               width = 0.14, offset = 0.01,
               colnames_angle = 0, colnames_offset_y = 10,
               hjust = 0.5, font.size = 0) +
  scale_fill_manual(values = myColsT_lineage, name = "T-lineage") +
  labs(title = "Global ML phylogeny of V. cholerae El Tor 7PET (n=3189)") +
  theme(plot.title = element_text(size = 18, face = "bold", hjust = 0.5),
        legend.position = "right",
        legend.box = "vertical",
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 12),
        # Make sure we DON'T blank the y-axis (time) after flipping:
        axis.title.x = element_blank(),
        axis.text.x  = element_blank(),
        axis.ticks.x = element_blank(),
        axis.title.y = element_text(),
        axis.text.y  = element_text(),
        axis.ticks.y = element_line()) +
  coord_flip() +
  scale_x_reverse(breaks = years, labels = years, name = "Year")
 
print(p1)

ggsave(file = paste0(getwd(),"/global-cholera-tree-lineage2.pdf"), plot = p1, width = 18, 
       height = 10, units = "in", dpi = 250, limitsize = FALSE)


