library(tidyverse)
library(ggplot2)

getwd()

dist_matrix <- read.csv("MEGA-result.pairwise.distance.csv", row.names = 1,  check.names = FALSE)
metadata <- read.delim("traits.beast.discrete.txt", stringsAsFactors = FALSE)

dist_long <- as.data.frame(as.table(as.matrix(dist_matrix)))

colnames(dist_long) <- c("Sample1", "Sample2", "Distance")

dist_long <- dist_long %>% 
  filter(Sample1 != Sample2) %>%
  rowwise() %>%
  mutate(pair = paste(sort(c(Sample1, Sample2)), collapse = "_")) %>%
  distinct(pair, .keep_all = TRUE)

dist_long <- dist_long %>%
  mutate(LogDistance = Distance*100)

dist_long <- dist_long %>%
  left_join(metadata, by = c("Sample1" = "name")) %>%
  rename(Cluster=group, Serotype1=serotype, Source1=source, Location1=location)

dist_long <- dist_long %>%
  left_join(metadata, by = c("Sample2" = "name")) %>%
  rename(Cluster2=group, Serotype2=serotype, Source2=source, Location2=location)

head(dist_long)

unique(dist_long$Cluster)

dist_long$Cluster <- factor(dist_long$Cluster, levels = c(
  'Group-5',
  'Group-4',
  'Group-3',
  'Group-2',
  'Group-1',
  'ctc',
  'env'

))


p <- ggplot(dist_long, aes(x = Cluster, y = LogDistance, fill = Cluster)) +
  geom_violin(alpha = 0.6) +
  theme_minimal() +
  labs(title = "", x = "", y = "Pairwise SNPs Distance") +
  scale_fill_manual(values = c(
    'Group-5' = "#FF9933",
    'Group-3' = "#8E063B",
    'Group-4' = "#78A5A1",
    'Group-2' = "#D5D5D5",
    'Group-1' = "#AD9024",
    'ctc'     = "#5B3794",
    'env'     = "#8EC280"
    
  )) +
  guides(fill = "none")
p

ggsave(file = "violin-pairwise-plot-final.pdf", 
       plot = p, width = 6, height = 4, 
       units = "in", dpi = 300, limitsize = FALSE)


