# ------------------------------------------------------------
# predtest.R
#
# A simple test framework for classification prediction
# algorithms.
#
# John Cardente
# 2013
#
# ------------------------------------------------------------


# ------------------------------------------------------------
# PERFORMANCE EVALUATION

pt.performance <- function(actual, predicted) {

   tp <- sum(actual==1&predicted==1)
   fp <- sum(actual==0&predicted==1)
   fn <- sum(actual==1&predicted==0)
   tn <- sum(actual==0&predicted==0)

   tpr <- tp/(tp+fn)
   fpr <- fp/(fp+tn)

   errrate   <- (fp+fn)/(tp+fp+tn+fn)
   recall    <- tp/(tp+fn)
   precision <- tp/(tp+fp)

   tpr       <- ifelse(is.na(tpr), 0, tpr)
   fpr       <- ifelse(is.na(fpr), 0, fpr)
   errrate   <- ifelse(is.na(errrate), 0, errrate)
   recall    <- ifelse(is.na(recall), 0, recall)
   precision <- ifelse(is.na(precision), 0, precision)
     
   perf.df <- data.frame(tp, 
                         fp,
                         tn,
                         fn,
                         tpr,
                         fpr,
                         errrate,
                         recall,
                         precision)
   perf.df
}


pt.avg.performance <- function(perf.df) {
  tmp <- apply(perf.df, 2, mean)
  tmp.df <- data.frame(t(tmp))

  tmp.df 
}


# ------------------------------------------------------------
# K FOLD VALIDATION

pt.kfold <- function(data, model) {
  
  k <- model$kfolds
  model.fn <- get(model$model.fn)

  if (k==1) {
    train.df <- data
    test.df <- data
    fold.results <- do.call(model.fn,
                            list(model,
                                 train.df, test.df))
    
  } else {
    
    bucket.size <- floor(nrow(data)/k)
    tmp.indexes <- seq(1,nrow(data))
    folds       <- c()
    for (i in seq(1,(k-1))) {
      fold.indexes <- sample(tmp.indexes, bucket.size)
      tmp.indexes  <- tmp.indexes[! tmp.indexes %in% fold.indexes]    
      folds        <- c(folds, list(fold.indexes))
    }
    folds <- c(folds, list(tmp.indexes))

    fold.results <- NULL
    for (i in seq(1,k)) {
      test.df      <- data[folds[[i]],]
      train.df     <- data[-folds[[i]],]
      perf         <- do.call(model.fn,
                              list(model,
                                   train.df, test.df))

      if (is.null(fold.results)) {
        fold.results <- perf
      } else {
        fold.results <- rbind(fold.results, perf)
      }
    }
    rownames(fold.results) <- NULL
  }

 fold.results
}


# ------------------------------------------------------------
# MAIN TEST ROUTINE

pt.test.models <- function (data, models) {

  # The models argument is a list of lists with the following elements:
  #
  #  name        - Model's name. (String).
  #  model.fn    - Name of model function (String).
  #  run         - Run model when TRUE (Boolean).
  #  avg.results - Average kfold results when TRUE (Boolean).
  #  dep.col     - Name of column to classify (String).
  #  indep.cols  - Name of columns to use for prediction (String vector).
  #  good.levels - Name of "good" levels for classification column (String vector).
  #  bad.levels  - Name of "bad" levels for classification column (String vector)
  #  balanced    - Enforce equal "good" and "bad" samples when TRUE (Boolean).
  #  kfolds      - Number of cross validation folds (Integer). 

  results <- data.frame()
  for (model in models) {
  
    # Extract model parameters
    name        <- model$name
    model.fn    <- model$model.fn
    run         <- model$run
    avg.results <- model$avg.results
    dep.col     <- model$dep.col
    indep.cols  <- model$indep.cols
    good.levels <- model$good.levels
    bad.levels  <- model$bad.levels
    balanced    <- model$balanced
    kfolds      <- model$kfolds

    # Skip this model if indicated
    if (!run) {
     next 
    }
    
    # Extract the columns this model cares about
    data.model <- data[,c(dep.col, indep.cols)]
    data.model <- data.model[complete.cases(data.model),]

    # Keep only the depedent variable levels of interest
    model.levels <- c(good.levels, bad.levels)
    keep.idxs <- as.character(data.model[,dep.col]) %in% model.levels
    data.model <- data.model[keep.idxs, ]

    # Create a balanced data set. Determine the number of
    # positive and negative samples. Use minimum as the
    # max number of samples from each. Take a random sample
    # from larger set to create an equal representation.
    if (balanced) {
      idx.pos <- which(data.model[,dep.col] %in% good.levels)
      idx.neg <- which(data.model[,dep.col] %in% bad.levels)
      num.pos <- length(idx.pos)
      num.neg <- length(idx.neg)
      num.limit <- min(num.pos, num.neg)
      
      data.model <- data.model[c(sample(idx.pos, num.limit),
                                 sample(idx.neg, num.limit)),]
    }


    # Run kfold validations, compute average performance,
    # and save results
    kfold.results <- pt.kfold(data, model)

    if (avg.results) {
      kfold.results <- pt.avg.performance(kfold.results)
    }
    
    results <- rbind(results,
                     cbind(data.frame(Model=rep(name, nrow(kfold.results))),
                           kfold.results))
    
  } # end model loop

  results
}
    

pt.model.template <- function(model,
                              train.df, test.df) {

  # Extract relevant parameters
  dep.col     <- model$dep.col
  indep.cols  <- model$indep.cols
  good.levels <- model$good.levels
  bad.levels  <- model$bad.levels

  # Build model using information in model list. Do prediction.
  # Store test results in actual and predicted variables.
  
  # Compute performance metrics
  #
  # NB - pt.performance expects actual and predicted
  #      to be vectors of 0 and 1. 
  perf.df <- pt.performance(actual, predicted)
  
  perf.df
}
