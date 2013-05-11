PredTest: A Simple Classifier Test Framework for R
--------------------------------------------------


### Overview


This is a simple classifier test framework for R that I created while
experimenting with solutions to Kaggle's [Titanic challenge](http://www.kaggle.com/c/titanic-gettingStarted).  
While trying out different models and feature combinations, I found it
helpful to have a way to easily test and compare results. I've since
reused this framework for other classification projects and it's been handy. 

There are very good, robust R packages that do similar things. This is
just a simple tool to facilitate experimenting with classifiers.

### Usage


The framework code is in `src/predtest.R`. To load it, source
the file in your R environment or script.

  source("src/predtest.R")

Two things are required to use the framework.

1. One or more model functions that confirm to the framework's API.
2. A list of models and parameters for the framework to execute.

The model functions have the form,

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

Model functions take three arguments:

* `model` - a list of parameters
* `train.df` - a dataframe containing the training data set.
* `test.df` - a dataframe containing the test data set.

They return a dataframe containing various performance metrics
produced by the `pt.performance` framework function. This function
takes as arguments (0,1) vectors of the actual and predicted
classifications.

To complete the model function, implement the appropriate library
calls to train a model using the training data set, test it with the
test data set, and process the results to create the `actual` and
`predicted` vectors. The provided examples demonstrate how to do this.

A model is described by a list with the following elements,

* name        - Model's name. (String).
* model.fn    - Name of model function (String).
* run         - Run model when TRUE (Boolean).
* avg.results - Average kfold results when TRUE (Boolean).
* dep.col     - Name of column to classify (String).
* indep.cols  - Name of columns to use for prediction (String vector).
* good.levels - Name of "good" levels for classification column (String vector).
* bad.levels  - Name of "bad" levels for classification column (String vector)
* balanced    - Enforce equal "good" and "bad" samples when TRUE (Boolean).
* kfolds      - Number of cross validation folds (Integer). 

The primary framework entry point, `pt.test.models()`, takes a list of such model lists
along with the associated data set. This excerpt from the Iris example
demonstrates this,

    data(iris)

    dep.col     <- "Species"
    indep.cols  <- c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width")
    good.levels <- "setosa"
    bad.levels  <- c("versicolor", "virginica" )
    
    models <- list(list(name        = "Decision Tree",
                        model.fn    = "iris.dtree",
                        run         = TRUE,
                        avg.results = TRUE, 
                        dep.col     = dep.col,
                        indep.cols  = indep.cols, 
                        good.levels = good.levels,
                        bad.levels  = bad.levels,
                        balanced    = FALSE,                    
                        kfolds      = 2),
                   
                   list(name        = "Naive Bayes",
                        model.fn    = "iris.nbayes",
                        run         = TRUE,
                        avg.results = TRUE,                     
                        dep.col     = dep.col,
                        indep.cols  = indep.cols, 
                        good.levels = good.levels,
                        bad.levels  = bad.levels,
                        balanced    = FALSE,
                        kfolds      = 2))
    
    pt.test.models(iris, models)

Each model descriptor can reference a different model function or the
same model function with different parameters (i.e. independent
variable columns, good/bad levels, etc). 

When run, the `pt.test.models()` routine will return a data frame
with the results for each model. As an example, here are the results
from running the Iris example,

    > pt.test.models(iris, models)
              Model tp fp tn fn tpr fpr errrate recall precision
    1 Decision Tree 25  0 50  0   1   0       0      1         1
    2   Naive Bayes 25  0 50  0   1   0       0      1         1


The columns of this data frame are,

* Model - name of the tested model. 
* tp - number of true positive results. 
* fp - number of false positive results. 
* tn - number of true negative results.
* fn - number of false negative results. 
* tpr - Proportion of true positives to true positives and false negatives.
* fpr - Proportion of false positives to false positives and true negatives.
* errrate - Proportion of incorrect predictions to total number of predictions. 
* recall - Proportion of true positives to true positives and false negatives. 
* precision - Proportion of true positives to true positives and false positives.

Some of these metrics don't make sense when averaged over the cross
validation folds. Setting the model parameter `avg.results` to `FALSE`
will cause the results from each cross validation test to be
returned. For example, setting this parameter to `FALSE` for the Iris 
example results in,

    > pt.test.models(iris, models)
              Model tp fp tn fn tpr fpr errrate recall precision
    1 Decision Tree 23  0 52  0   1   0       0      1         1
    2 Decision Tree 27  0 48  0   1   0       0      1         1
    3   Naive Bayes 25  0 50  0   1   0       0      1         1
    4   Naive Bayes 25  0 50  0   1   0       0      1         1

### Examples

Two example uses of the framework are provided. 

* Iris - example Decision Tree and Naive Bayes classifiers for the [iris data set](http://en.wikipedia.org/wiki/Iris_flower_data_set).
* Magic04 - example SVM and Logistic Regression classifiers for [UCI MAGIC Gamma Telescope data set]( http://archive.ics.uci.edu/ml/datasets/MAGIC+Gamma+Telescope).

