getwd()
setwd("/Users/Juan/UFL Dropbox/Juan Perez Jimenez/2.Workspace/Bayes-factor/2025/campsites/")

library(knitr) #required for calculateBF and lograteextract
library(tidyverse) #required for lograteextract and filterrates
library(RColorBrewer) #required for plotmigrationevents

source("/Users/Juan/UFL Dropbox/Juan Perez Jimenez/1.UF/1_EPI/1.Tesis-project-I/Workspace/2025.analysis/graphs/phylogeography/bayesian_functions_1.R")

loc = read.csv2(file = "vc-camps.data.csv", header = T, sep = ",", comment.char = "#")
testloc = unique(loc$cluster)
#View(as.data.frame(testloc))

calculateBF(logfile = "vc.drc.2025.onlycamps-rc-bs-400m.cluster.rates.log", 
            traitname = "cluster",
            locations = testloc, burninpercentage = 10)

#Bayes Factor approximation calculated and saved on a csv file (location.BFs.csv) in your working folder."


