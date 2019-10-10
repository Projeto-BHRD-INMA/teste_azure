##################################
# testes azure 2                 #
# Kele Rocha Firmiano            #
# 07/10/19                       #  
##################################

start_time <- Sys.time()
############################## 1_setup_sdmdata ##############################

# Packages
library(modleR)
library(raster)
library(dplyr)
library(foreach)
library(parallel)

# Loading pca environment data (pca axes, see script "0.1_get_envdata")
clim <- list.files(path="data/pca", ".*.tif$", 
                   full.names = TRUE)

clim.stack <- stack(clim) 
plot(clim.stack)  

# Loading occurrence data
data<-read.csv("data/AMSul_arvores.csv", header = T, sep=";", dec=".")
species <- sort(unique(data$especies))
species

occs <- filter(data, especies == species[98]) %>% dplyr::select(lon, lat) #sp 98: Eremanthus erythropappus

modelos <- "modelos" 

dim(occs)

table(data$especies) %>% sort() 

sdmdata_1sp <- setup_sdmdata(species_name = species[98],
                             occurrences = occs,
                             predictors = clim.stack,
                             models_dir = modelos,
                             partition_type = "crossvalidation",
                             cv_partitions = 5,
                             cv_n = 1,
                             seed = 512,
                             buffer_type = "mean",
                             plot_sdmdata = T,
                             n_back = 500,
                             clean_dupl = F,
                             clean_uni = F,
                             clean_nas = F,
                             geo_filt = F, 
                             #geo_filt_dist = 10,
                             select_variables = F)
#percent = 0.5,
#cutoff = 0.7)

############################## 2_do_many ##############################

#do_many(species_name = species[98],
#        predictors = clim.stack,
#        models_dir = modelos,
#        write_png = T,
#        write_bin_cut = F,
#        bioclim = T,
#        domain = T, 
#        glm = T,
#        svmk = T,
#        svme = T, 
#        maxent = T,
#        maxnet = T,
#        rf = T,
#        mahal = F, 
#        brt = T, 
#        equalize = T)

############################## 2_do_any ##############################
# do_any in parallel

#no_cores <- detectCores()
no_cores <- detectCores() - 1
cl <- makeCluster(no_cores)

#algos <- c("bioclim", "brt", "domain", "maxent", "glm", "mahal", "svme", "svmk", "rf")
algos <- c("bioclim", "brt", "domain", "glm", "mahal", "svme", "svmk", "rf")

foreach(i=1:8) %dopar% (do_any(species_name = species[98],
                               algo = algos[i],
                               predictors = clim.stack,
                               models_dir = modelos,
                               equalize = T))
stopCluster(cl)
############################## 3_final_model ##############################

final_model(species_name = species[98],
            algorithms = NULL,
            models_dir = modelos,
            final_dir = "final_models",
            proj_dir = "present",
            select_partitions = TRUE,
            select_par = "TSS",
            select_par_val = 0,
            which_models = c("raw_mean", "bin_consensus"),
            consensus_level = 0.5,
            uncertainty = T,
            overwrite = T)

############################## 4_final_ensemble ##############################

ensemble <- "ensemble"

ens <- ensemble_model(species[98],
                      occurrences = occs,
                      models_dir = modelos,
                      final_dir = "final_models",
                      ensemble_dir = "ensemble",
                      proj_dir = "present",
                      which_models = c("raw_mean", "bin_consensus"),
                      consensus = FALSE, 
                      consensus_level = 0.5,
                      write_ensemble = TRUE, 
                      scale_models = TRUE)

#############################################################################
end_time <- Sys.time()
total_time <- end_time - start_time
total_time