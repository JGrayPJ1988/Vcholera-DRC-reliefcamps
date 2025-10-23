##############################################################################
### By Juan Perez Jimenez #########################
### Date: 07-24-2024   ############################
### Molecular EPI #################################
###################################################

# loading lybraries
library(readr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(reshape2)
library(tibble)
library(tidyverse)
library(patchwork)

# setting workspace up
getwd()

data <- read.table(pipe("pbpaste"), header = T, sep = "\t", na=c("na", "NA", ""))

data$date <- parse_date_time(data$date, orders = c("b-Y", "b -Y"))

df_suspected <- data %>% filter(cases == "suspected")
df_confirmed <- data %>% filter(cases == "confirmed")


place_cols <- c("Bulengo","Bushagara","Kanyaruchinya","Kibati",
                "Munigi","Nzulo","Rusayo","Don.Bosco","Buhimba")

### SUSPECTED CASES
df_norm_suspected <- df_suspected %>%                               
  mutate(across(all_of(place_cols), ~ suppressWarnings(as.numeric(.)))) %>%
  rowwise() %>%
  mutate(
    month_max = max(c_across(all_of(place_cols)), na.rm = TRUE),
    month_max = ifelse(is.finite(month_max), month_max, NA_real_)
  ) %>%
  mutate(across(all_of(place_cols),
                ~ ifelse(!is.na(month_max) && month_max > 0, .x / month_max, NA_real_),
                .names = "{.col}_norm")) %>%
  ungroup() %>%
  select(month, year, date, cases, ends_with("_norm"))

norm_long_suspected <- df_norm_suspected %>%
  select(date, ends_with("_norm")) %>%
  tidyr::pivot_longer(-date, names_to = "place", values_to = "norm") %>%
  dplyr::mutate(place = sub("_norm$", "", place))

### CONFIRMED CASES
df_norm_confirmed <- df_confirmed %>%                               
  mutate(across(all_of(place_cols), ~ suppressWarnings(as.numeric(.)))) %>%
  rowwise() %>%
  mutate(
    month_max = max(c_across(all_of(place_cols)), na.rm = TRUE),
    month_max = ifelse(is.finite(month_max), month_max, NA_real_)
  ) %>%
  mutate(across(all_of(place_cols),
                ~ ifelse(!is.na(month_max) && month_max > 0, .x / month_max, NA_real_),
                .names = "{.col}_norm")) %>%
  ungroup() %>%
  select(month, year, date, cases, ends_with("_norm"))

norm_long_confirmed <- df_norm_confirmed %>%
  select(date, ends_with("_norm")) %>%
  tidyr::pivot_longer(-date, names_to = "place", values_to = "norm") %>%
  dplyr::mutate(place = sub("_norm$", "", place))

# Order you want in the heatmap
place_order <- c("Nzulo","Bulengo","Buhimba","Rusayo",
                 "Don.Bosco","Bushagara","Munigi","Kanyaruchinya","Kibati")

 # optional: order facets

long_suspected <- norm_long_suspected %>%
  mutate(Region = case_when(
    place %in% c("Nzulo","Bulengo","Buhimba","Rusayo") ~ "West",
    place %in% c("Don.Bosco","Bushagara","Munigi","Kanyaruchinya","Kibati") ~ "East",
    #Camp %in% c("Don.Bosco") ~ "Southwest",
    TRUE ~ "Other"  # Catch any camps not classified
  ))
# Apply to suspected and confirmed data
long_suspected <- long_suspected %>%
  mutate(place  = factor(place,  levels = place_order),
         Region = factor(Region, levels = c("West","East"))) 

long_confirmed <- norm_long_confirmed %>%
  mutate(Region = case_when(
    place %in% c("Nzulo","Bulengo","Buhimba","Rusayo") ~ "West",
    place %in% c("Don.Bosco","Bushagara","Munigi","Kanyaruchinya","Kibati") ~ "East",
    #Camp %in% c("Don.Bosco") ~ "Southwest",
    TRUE ~ "Other"
  ))
long_confirmed <- long_confirmed %>%
  mutate(place  = factor(place,  levels = place_order),
         Region = factor(Region, levels = c("West","East")))

long_suspected$date <- as.Date(long_suspected$date)
long_confirmed$date <- as.Date(long_confirmed$date)

# Suspected cases plot
p1 <- ggplot(long_suspected, aes(x = place, y = date, fill = norm)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "white", high = "#DB5920", na.value = "grey90") +
  labs(title = "Suspected Cholera Cases", x = NULL, y = NULL, fill = "Cases") +
  facet_wrap(~Region, scales = "free_x") +
  scale_y_date(
    breaks = seq(as.Date("2022-10-01"), as.Date("2024-12-01"), by = "1 month"),
    date_labels = "%Y %b",
    limits = c(as.Date("2022-10-01"), as.Date("2024-12-01"))
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text.y = element_text(size = 6),
    panel.grid.major = element_line(color = "white"),
    panel.grid.minor = element_line(color = "white"),
    panel.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "white", color = NA),
    strip.text = element_text(face = "bold")
  )

# Confirmed cases plot
p2 <- ggplot(long_confirmed, aes(x = place, y = date, fill = norm)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "white", high = "#C02B40", na.value = "grey90") +
  labs(title = "Confirmed Cholera Cases", x = NULL, y = NULL, fill = "Cases") +
  facet_wrap(~Region, scales = "free_x") +
  scale_y_date(
    breaks = seq(as.Date("2022-10-01"), as.Date("2024-03-01"), by = "1 month"),
    date_labels = "%Y %b",
    limits = c(as.Date("2022-10-01"), as.Date("2024-03-01"))
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.text.y = element_text(size = 6),
    panel.grid.major = element_line(color = "white"),
    panel.grid.minor = element_line(color = "white"),
    panel.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "white", color = NA),
    strip.text = element_text(face = "bold")
  )

# Combine vertically
c <- p1 / p2
c
ggsave(file = paste0(getwd(),"/heatmap.vc.camps.cases_2.pdf"), plot = c, width = 6, 
       height = 7, units = "in", dpi = 300, limitsize = FALSE)
