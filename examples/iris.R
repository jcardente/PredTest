# ------------------------------------------------------------
# Iris Example
#
# Example of using the PredTest framework to test
# classifiers for the Iris data set.
#
# http://en.wikipedia.org/wiki/Iris_flower_data_set
#
# John Cardente
# 2013
#
# ------------------------------------------------------------

library(tree)
library(e1071)

source("../src/predtest.R")


# ------------------------------------------------------------
# MODELS

iris.dtree <- function (model,
                      train.df, test.df) {

  dep.col     <- model$dep.col
  indep.cols  <- model$indep.cols
  good.levels <- model$good.levels
  bad.levels  <- model$bad.levels

  # For simplicity, create a new column for clasification
  train.df$Good.Class <- ifelse(train.df[,dep.col] %in% good.levels, 1, 0)
  test.df$Good.Class  <- ifelse(test.df[,dep.col] %in% good.levels, 1, 0)
    
  # Fit decision tree and predict against results
  fit.formula <- as.formula(paste0("Good.Class ~ ", 
                                   paste(indep.cols, collapse=" + ")))
  fit <- tree(fit.formula, train.df)

  predicted <- predict(fit, test.df)
  actual  <- ifelse(test.df[,dep.col] %in% good.levels, 1, 0)
  perf.df <- pt.performance(actual, predicted)
  
  perf.df
}


iris.nbayes <- function(model,
                      train.df, test.df) {

  dep.col     <- model$dep.col
  indep.cols  <- model$indep.cols
  good.levels <- model$good.levels
  bad.levels  <- model$bad.levels

  # For simplicity, create a new column for clasification
  train.df$Good.Class <- factor(ifelse(train.df[,dep.col] %in% good.levels, "Yes", "No"), levels=c("No","Yes"))
  test.df$Good.Class  <- factor(ifelse(test.df[,dep.col] %in% good.levels, "Yes", "No"), levels=c("No","Yes"))
   
  # Fit Naive Bayes model
  fit.formula <- as.formula(paste0("Good.Class ~ ", 
                                   paste(indep.cols, collapse=" + ")))

  fit <- naiveBayes(fit.formula, data=train.df)

  predicted <- ifelse(as.character(predict(fit, test.df, type='class')) == "Yes",
                      1, 0)
  actual    <- ifelse(test.df[,dep.col] %in% good.levels, 1, 0)
  perf.df <- pt.performance(actual, predicted) 

  perf.df   
}


# ------------------------------------------------------------
# MAIN TEST

data(iris)

dep.col     <- "Species"
indep.cols  <- c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")
good.levels <- "setosa"
bad.levels  <- c("versicolor", "virginica" )

models <- list(list(name        = "Decision Tree",
                    model.fn    = "iris.dtree",
                    run         = TRUE,
                    avg.results = FALSE, 
                    dep.col     = dep.col,
                    indep.cols  = indep.cols, 
                    good.levels = good.levels,
                    bad.levels  = bad.levels,
                    balanced    = FALSE,                    
                    kfolds      = 2),
               
               list(name        = "Naive Bayes",
                    model.fn    = "iris.nbayes",
                    run         = TRUE,
                    avg.results = FALSE,                     
                    dep.col     = dep.col,
                    indep.cols  = indep.cols, 
                    good.levels = good.levels,
                    bad.levels  = bad.levels,
                    balanced    = FALSE,
                    kfolds      = 2))

pt.test.models(iris, models)
