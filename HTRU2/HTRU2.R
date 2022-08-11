#####################
# HTRU2 data analysis
#####################

# Note: this process could take a couple of minutes

if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
if(!require(plotly)) install.packages("plotly", repos = "http://cran.us.r-project.org")
if(!require(R.utils)) install.packages("R.utils", repos = "http://cran.us.r-project.org")
if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")

library(caret)
library(plotly)
library(R.utils)
library(tidyverse)

# HTRU2 dataset:
# https://archive-beta.ics.uci.edu/ml/datasets/htru2
# https://archive.ics.uci.edu/ml/machine-learning-databases/00372/HTRU2.zip
# intro: https://www.mpifr-bonn.mpg.de/research/fundamental/htru
# about pulsar surveys: https://www.mpifr-bonn.mpg.de/research/fundamental/pulsarsurveys
# citation: https://doi.org/10.1093/mnras/stw656

# What do the instances that comprise the dataset represent?
# Each candidate is described by 8 continuous variables, and a single class variable. The first four are simple statistics obtained from the integrated pulse profile (folded profile). This is an array of continuous variables that describe a longitude-resolved version of the signal that has been averaged in both time and frequency (see [3] for more details). The remaining four variables are similarly obtained from the DM-SNR curve (again see [3] for more details). These are summarised below:

# 1. Mean of the integrated profile.
# 2. Standard deviation of the integrated profile.
# 3. Excess kurtosis of the integrated profile.
# 4. Skewness of the integrated profile.
# 5. Mean of the DM-SNR curve.
# 6. Standard deviation of the DM-SNR curve.
# 7. Excess kurtosis of the DM-SNR curve.
# 8. Skewness of the DM-SNR curve.
# 9. Class

# HTRU 2 Summary
# 17,898 total examples.
# 1,639 positive examples.
# 16,259 negative examples.


dl <- tempfile()
df_link <- "https://archive.ics.uci.edu/ml/machine-learning-databases/00372/HTRU2.zip"
download.file(df_link, dl)
dat <- read_csv(dl, col_names = FALSE)
colnames(dat) <- c("IP_mean", "IP_std_dev", "IP_excess_kurtosis", "IP_skewness",
                  "DM_SNR_mean", "DM_SNR_std_dev", "DM_SNR_excess_kurtosis",
                  "DM_SNR_skewness", "class")
dat$class <- as.factor(dat$class)

# Test set will be 20% of data set
set.seed(10, sample.kind = "Rounding") # if using R 3.5 or earlier, use `set.seed(1)`
test_index <- createDataPartition(y = dat$class, times = 1, p = 0.2, list = FALSE)
train_set <- dat %>% slice(-test_index)
test_set <- dat %>% slice(test_index)

# remove data structures that will not be needed hereafter
rm(dl, df_link, dat, test_index)



# Algorithm training
options(digits = 3)
models <- c('GLM', 'KNN', 'RF', 'SVM', 'RDA')

# glm
fit_glm <- train(class ~ ., method = "glm", data = train_set)
y_hat_glm <- predict(fit_glm, test_set)
acc_glm <- confusionMatrix(y_hat_glm, factor(test_set$class))$overall[["Accuracy"]]
acc_glm # 0.977



# k-Nearest Neighbors
fit_knn <- train(class ~ ., method = "knn", data = train_set)
fig_knn <- plot_ly(x = fit_knn$results$k, 
                   y = fit_knn$results$Accuracy,
                   type = "scatter",
                   mode = "marker",
                   error_y = list(array = fit_knn$results$AccuracySD))
fig_knn <- fig_knn %>% 
  layout(title = "KNN Model",
         xaxis = list(title = "Neighbors"),
         yaxis = list(title = "Accuracy"))
fig_knn
y_hat_knn <- predict(fit_knn, test_set)
acc_knn <- confusionMatrix(y_hat_knn, factor(test_set$class))$overall[["Accuracy"]]
acc_knn # 0.973



# Random Forest
mtrys <- seq(5, 25, 10)
set.seed(10, sample.kind = "default") # if using R 3.6 or later
fit_rf <- train(class ~ .,
             method = "rf", 
             data = train_set, 
             nodesize = 1, 
             tuneGrid = data.frame(mtry = mtrys))

plot(fit_rf, 
     main = "Random Forest - number of predictors", 
     highlight = TRUE) # number of predictors and performance
fit_rf$bestTune
# variable importance
imp_rf <- varImp(fit_rf)
fig_rf <- plot_ly(x = imp_rf$importance$Overall,
                  y = colnames(train_set[1:8]),
                  type = "bar")
fig_rf <- fig_rf %>% 
  layout(title = "Random Forest - variable importance",
         xaxis = list(title = "Importance"),
         yaxis = list(title = "Predictor Variable"))
fig_rf

y_hat_rf <- predict(fit_rf, newdata = test_set)
acc_rf <- confusionMatrix(y_hat_rf, test_set$class)$overall[["Accuracy"]]
acc_rf # 0.98



# Support Vector Machine
fit_svm <- train(class ~ ., method = "svmRadial", data = train_set)
y_hat_svm <- predict(fit_svm, test_set)
acc_svm <- confusionMatrix(y_hat_svm, factor(test_set$class))$overall[["Accuracy"]]
acc_svm # 0.979



# Regularized Discriminant Analysis
fit_rda <- train(class ~ ., method = "rda", data = train_set)
y_hat_rda <- predict(fit_rda, test_set)
acc_rda <- confusionMatrix(y_hat_rda, factor(test_set$class))$overall[["Accuracy"]]
acc_rda # 0.974



# model comparison
fig <- plot_ly(x = test_set$class, name = "actual", type = 'histogram')
fig <- fig %>% add_trace(x = y_hat_glm, name = "GLM", type = 'histogram')
fig <- fig %>% add_trace(x = y_hat_knn, name = "KNN", type = 'histogram')
fig <- fig %>% add_trace(x = y_hat_rf, name = "RF", type = 'histogram')
fig <- fig %>% add_trace(x = y_hat_svm, name = "SVM", type = 'histogram')
fig <- fig %>% add_trace(x = y_hat_rda, name = "RDA", type = 'histogram')
fig <- fig %>%
  layout(title = "Out of sample predictions",
         xaxis = list(title = "Signal"),
         yaxis = list(title = "Count"),
         barmode = 'group')
fig

models_compare <- resamples(list(
  GLM = fit_glm,
  KNN = fit_knn,
  RF = fit_rf,
  SVM = fit_svm,
  RDA = fit_rda
))

summary(models_compare)



# model ensemble

rows <- 1:length(test_set$class)
n <- length(models)
y_hat <- sapply(rows, function(rows){
  x <- ifelse(y_hat_glm[rows] == 1, 1, 0)
  x <- x + ifelse(y_hat_knn[rows] == 1, 1, 0)
  x <- x + ifelse(y_hat_rf[rows] == 1, 1, 0)
  x <- x + ifelse(y_hat_svm[rows] == 1, 1, 0)
  x <- x + ifelse(y_hat_rda[rows] == 1, 1, 0)
  ifelse(x >= 3, 1, 0)
}) %>% factor

acc_ensemble <- confusionMatrix(y_hat, test_set$class)$overall[["Accuracy"]]
acc_ensemble # 0.978



# From our results, the shape of the integrated pulse profile and its statistics are the main factors to determine whether the spectra measured by the detector corresponds to a pulsar or background noise. Moreover, the choice of the classification algorithm does not impact much the accuracy of the results.