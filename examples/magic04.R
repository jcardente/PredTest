# ------------------------------------------------------------
# Magic Example
#
# Example of using the PredTest framework to test
# classifiers for the UCI MAGIC Gamma Telescope
# data set.
#
# http://archive.ics.uci.edu/ml/datasets/MAGIC+Gamma+Telescope
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

magic.logit <- function(model,
                     train.df, test.df) {

  dep.col     <- model$dep.col
  indep.cols  <- model$indep.cols
  good.levels <- model$good.levels
  bad.levels  <- model$bad.levels

  # For simplicity, create a new column for clasification
  train.df$Good.Class <- factor(ifelse(train.df[,dep.col] %in% good.levels, "Yes", "No"), levels=c("No","Yes"))
  test.df$Good.Class  <- factor(ifelse(test.df[,dep.col] %in% good.levels, "Yes", "No"), levels=c("No","Yes"))
   
  # Fit logistic regression model
  fit.formula <- as.formula(paste0("Good.Class ~ ", 
                                   paste( "poly(",
                                         indep.cols,
                                         ", degree=2)",
                                         collapse="+")))
  
  fit <- glm(fit.formula, data=train.df, family=binomial(link="logit"))
  
  predicted <- ifelse(predict(fit, test.df, type='response') >= 0.5, 1, 0)
  actual    <- ifelse(test.df[,dep.col] %in% good.levels, 1, 0)
  perf.df <- pt.performance(actual,
                            predicted)
  
  perf.df   
}

magic.svm <- function (model,
                    train.df, test.df) {

  dep.col     <- model$dep.col
  indep.cols  <- model$indep.cols
  good.levels <- model$good.levels
  bad.levels  <- model$bad.levels

  # For simplicity, create a new column for clasification
  train.df$Good.Class <- factor(ifelse(train.df[,dep.col] %in% good.levels, "Yes", "No"), levels=c("No","Yes"))
  test.df$Good.Class  <- factor(ifelse(test.df[,dep.col] %in% good.levels, "Yes", "No"), levels=c("No","Yes"))
   
  # Fit Support vector machine
  fit.formula <- as.formula(paste0("Good.Class ~ ", 
                                   paste(indep.cols, collapse=" + ")))

  fit <- svm(fit.formula, train.df, type="C-classification")
  predicted <- ifelse(as.character(predict(fit, test.df, type='response')) == "Yes", 1, 0)

  actual    <- ifelse(test.df[,dep.col] %in% good.levels, 1, 0)
  perf.df <- pt.performance(actual,
                            predicted)

  perf.df   
}

# ------------------------------------------------------------
# MAIN TEST

magic <- read.table("http://archive.ics.uci.edu/ml/machine-learning-databases/magic/magic04.data", header = F, sep=",")
#magic <- read.table("magic04.data", header = F, sep=",")

dep.col     <- colnames(magic)[ncol(magic)]
indep.cols  <- colnames(magic)[-ncol(magic)]
good.levels <- c("h")
bad.levels  <- c("g")

models <- list(list(name        = "SVM",
                    model.fn    = "magic.svm",
                    run         = FALSE,
                    avg.results = FALSE, 
                    dep.col     = dep.col,
                    indep.cols  = indep.cols, 
                    good.levels = good.levels,
                    bad.levels  = bad.levels,
                    balanced    = TRUE,
                    kfolds      = 10),

               list(name        = "Logit",
                    model.fn    = "magic.logit",
                    run         = TRUE,
                    avg.results = FALSE,
                    dep.col     = dep.col,
                    indep.cols  = indep.cols, 
                    good.levels = good.levels,
                    bad.levels  = bad.levels, 
                    balanced    = TRUE,
                    kfolds      = 10))


pt.test.models(magic, models)

