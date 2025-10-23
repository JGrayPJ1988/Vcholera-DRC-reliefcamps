##############################################################################
### By Juan Perez Jimenez #########################
### Date: 07-24-2024   ############################
### Molecular EPI #################################
###################################################

# loading lybraries
library(readr)
library(dplyr)
library(ggplot2)
library(tibble)
library(tidytext) 

# setting workspace up
getwd()

data <- read.table(pipe("pbpaste"), header = T, sep = "\t")
str(data)
data$year <- floor(data$date.dec)
str(data)

data2 <- data %>% 
  filter(source=="campsite")

lvl <- c('Group-5','Group-4','Group-3','Group-2','Group-1')

summary_by_slc <- data2 %>%
  group_by(year, location, cluster) %>%
  summarise(total_records = n(), .groups = "drop") %>%
  mutate(
    cluster = factor(cluster, levels = lvl),
    # order locations within each year by the cluster code
    location_ord = reorder_within(location, as.integer(cluster), year, fun = min)
  )

p <- ggplot(summary_by_slc, aes(x = location_ord, y = total_records, fill = cluster)) +
  geom_col(position = position_stack(reverse = FALSE)) +
  facet_wrap(~ year, scales = "free_x") +
  scale_x_reordered(name = "Relief Camps") +  # cleans the labels back to 'location'
  scale_fill_manual(
    limits = lvl,  # controls stack + legend order
    values = c(
      'Group-5'='#FF9933','Group-4'='#78A5A1','Group-3'='#8E063B','Group-2'='#D5D5D5',
      'Group-1'='#AD9024')
  ) +
  labs(title = "Total Genomes Sequenced By Relief Camp", y = "Total genomes") +
  theme(panel.background = element_rect(fill = "white", colour = "grey20")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom", legend.title = element_blank())

p
        
ggsave(file = paste0(getwd(),"/summary.relief_camps_by_year_final.pdf"), plot = p, width = 6, 
       height = 4, units = "in", dpi = 300, limitsize = FALSE)

