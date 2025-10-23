# Load required packages
library(ggplot2)
library(readr)
library(dplyr)
library(tibble)
library(smoother)
library(zoo)

# Read data from clipboard (replace with actual file paths if needed)
data <- read_delim(pipe("pbpaste"), delim = "\t", col_types = cols())

# Ensure date format is consistent
data$date_clean <- as.Date(data$date, format = "%m/%d/%y")

# Plot: Ne with log10 scale on y-axis
p1 <- ggplot(data, aes(x = date_clean, y = mean)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = "#9ECFDD", alpha = 0.2) +
  geom_line(color = "#225188", size = 1) +
  scale_y_log10(labels = scales::comma_format()) +
  scale_x_date(
    breaks = seq(as.Date("2022-10-01"), as.Date("2024-12-01"), by = "6 month"),
    date_labels = "%Y-%m",
    limits = c(as.Date("2022-10-01"), as.Date("2024-12-01"))
  ) +
  labs(
    y = expression("Effective Population Size (Ne)"),
    x = "",
    title = "Bayesian SkyGrid Plot"
  ) +
  theme_minimal(base_size = 12)

# Print the plot
print(p1)
ggsave(filename = file.path(getwd(), "skyGrid-pop-size-camps.pdf"), 
       plot = p1, width = 6, height = 4, units = "in", dpi = 300)

library(lubridate)
camps_cases <- read_delim(pipe("pbpaste"), delim = "\t", col_types = cols())
camps_cases <- camps_cases %>%
  mutate(date_clean = my(date))
camps_cases$date_clean <- as.Date(camps_cases$date_clean, format = "%m/%y")

drc_cases <- read_delim(pipe("pbpaste"), delim = "\t", col_types = cols())

# Basic time series plot
p <- ggplot(camps_cases, aes(x = date_clean, y = cases_camps)) +
  geom_line(color = "darkorange", size = 1) +
  geom_point(color = "darkred", size = 2) +
  scale_x_date(
    date_breaks = "2 months",
    date_labels = "%b-%y"
  ) +
  labs(
    title = "",
    x = "",
    y = "Cholera Cases"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank()
  )

# Print the plot
print(p)

ggsave(filename = file.path(getwd(), "Camps-cases-drc.pdf"), 
       plot = p, width = 6, height = 4, units = "in", dpi = 300)


merged_df <- merge(camps_cases, data, by = "date_clean", all = TRUE)


df <- merged_df %>%
  group_by(date_clean,mean,upper,lower,cases_camps) %>%
  summarise(
    total_records = n())
print(df)


# Part 2 after cleaning the data
df2 <- read.table(pipe("pbpaste"), header = T, sep = "\t")
df2$date_clean <- as.Date(df2$date, format = "%m/%d/%y")
df2$Cases <- na.locf(na.locf(df2$Cases, na.rm = FALSE), fromLast = TRUE)

p2 <- ggplot(df2, aes(x = date_clean)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = "#9ECFDD", alpha = 0.2) +
  geom_line(aes(y = mean), color = "#225188", size = 1) +
  
  geom_line(
    aes(y = Cases / max(Cases, na.rm = TRUE) * 100),
    color = "darkorange",
    size = 1
  ) +
  geom_point(
    aes(y = Cases / max(Cases, na.rm = TRUE) * 100),
    color = "darkred",
    size = 2
  ) +
  
  scale_y_log10(
    limits = c(0.1, 100),
    breaks = c(0.1, 1, 10, 100),
    name = "Effective Population Size (Ne)",
    sec.axis = sec_axis(
      trans = ~ . * max(df2$Cases, na.rm = TRUE) / 100,
      name = "Cholera Cases"
    )
  ) +
  
  scale_x_date(
    breaks = seq(as.Date("2022-10-01"), as.Date("2024-12-01"), by = "1 year"),
    date_labels = "%Y",
    limits = c(as.Date("2022-10-01"), as.Date("2024-12-01"))
  ) +
  
  labs(
    x = "",
    title = ""a
  ) +
  theme_minimal(base_size = 14)
p2

ggsave(filename = file.path(getwd(), "skyGrid-pop-size-with-cases.pdf"), 
       plot = p2, width = 6, height = 4, units = "in", dpi = 300)

# Define a scaling factor to bring cases into Ne scale range
case_factor <- max(df2$mean, na.rm = TRUE) / max(df2$Cases, na.rm = TRUE)

p2 <- ggplot(df2, aes(x = date_clean)) +
  # Ne: SkyGrid ribbon + line
  geom_ribbon(aes(ymin = lower, ymax = upper), fill = "#9ECFDD", alpha = 0.2) +
  geom_line(aes(y = mean), color = "#225188", size = 1) +
  
  # Cholera cases transformed to match left y-axis
  geom_line(
    aes(y = Cases * case_factor),
    color = "darkorange",
    size = 1
  ) +
  geom_point(
    aes(y = Cases * case_factor),
    color = "darkred",
    size = 2
  ) +
  
  # Primary Y axis: log10 scale for Ne
  scale_y_log10(
    name = "Effective Population Size (Ne)",
    
    # Secondary axis shows actual Cholera Cases (reverse transformation)
    sec.axis = sec_axis(
      trans = ~ . / case_factor,
      name = "Cholera Cases"
    ),
    
    limits = c(0.1, 100),
    breaks = c(0.1, 1, 10, 100)
  ) +
  
  # X axis: yearly
  scale_x_date(
    breaks = seq(as.Date("2022-10-01"), as.Date("2024-12-01"), by = "1 year"),
    date_labels = "%Y",
    limits = c(as.Date("2022-10-01"), as.Date("2024-12-01"))
  ) +
  
  labs(x = "", title = "") +
  
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x = element_text(angle = 0, hjust = 1)
  )

p2

ggsave(filename = file.path(getwd(), "skyGrid-pop-size-with-cases-2.pdf"), 
       plot = p2, width = 6, height = 4, units = "in", dpi = 300)

