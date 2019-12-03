# mcp: Regression with Multiple Change Points

[![Travis-CI status](https://travis-ci.org/lindeloev/mcp.svg?branch=master)](https://travis-ci.org/lindeloev/mcp)
[![Coveralls status](https://codecov.io/gh/lindeloev/mcp/branch/master/graph/badge.svg)](https://coveralls.io/r/lindeloev/mcp)
[![CRAN status](https://www.r-pkg.org/badges/version/mcp)](https://CRAN.R-project.org/package=mcp)


`mcp` does regression with one or Multiple Change Points (MCP) between Generalized and hierarchical Linear Segments using Bayesian inference. `mcp` aims to provide maximum flexibility for analyses with a priori knowledge about the number of change points and the form of the segments in between.

Change points are also called **switch points**, **break points**, **broken line** regression, **broken stick** regression, **bilinear** regression, **piecewise linear** regression, **local linear** regression, **segmented** regression, and (performance) **discontinuity** models. `mcp` aims to be be useful for all of them. See how `mcp` compares to [other R packages](https://lindeloev.github.io/mcp/articles/packages.html).

Under the hood, `mcp` takes a formula-representation of linear segments and turns it into [JAGS](https://sourceforge.net/projects/mcmc-jags/) code. `mcp` leverages the power of `tidybayes`, `bayesplot`, `coda`, and `loo` to make change point analysis easy and powerful.


# Install

 1. <a href="https://sourceforge.net/projects/mcmc-jags/" target="_blank">Install the latest version of JAGS</a>. Linux users can fetch binaries <a href="http://mcmc-jags.sourceforge.net/" target="_blank">here</a>.
 
 2. Install `mcp` by running this in R:
 
    ```r
    if (!requireNamespace("remotes")) install.packages("remotes")
    remotes::install_github("lindeloev/mcp")
    ```



# Brief example
`mcp` takes a list of formulas - one for each segment. The change point(s) are the `x` at which data changes from being better predicted by one formula to the next. The first formula is just `response ~ predictors` and the most common formula for segment 2+ would be ` ~ predictors` (more details [here](https://lindeloev.github.io/mcp/articles/formulas.html)).

## Fit a model
The following model infers the two change points between three segments.

```r
library(mcp)

# Define the model
segments = list(
  response ~ 1,  # plateau (int_1)
  ~ 0 + time,    # joined slope (time_2) at cp_1
  ~ 1 + time     # disjoined slope (int_3, time_3) at cp_2
)

# Fit it. The `ex_demo` dataset is included in mcp
fit = mcp(segments, data = ex_demo)
```

## See results

Plot lines drawn randomly from the posterior on top of data to inspect the fit:
```r
plot(fit)
```
![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_demo.png)

Use `summary()` to summarise the posterior distribution as well as sampling diagnostics. They were simulated to lie at `cp_1 = 30` and `cp_2 = 70` and these values are well recovered, as are the other coefficients ([see how `ex_demo` was generated](https://github.com/lindeloev/mcp/tree/master/data-raw/ex_demo.R)). 

```r
summary(fit)
```
```r
Family: gaussian(link = 'identity')
Iterations: 9000 from 3 chains.
Segments:
  1: response ~ 1
  2: response ~ 1 ~ 0 + time
  3: response ~ 1 ~ 1 + time

Population-level parameters:
    name   mean  lower   upper Rhat n.eff    ts_se
    cp_1 31.167 23.620 39.7257 1.01   342 407.6290
    cp_2 69.772 69.305 70.2656 1.00  5801   0.1389
   int_1 10.333  8.895 11.6919 1.00  1063   3.8640
   int_3  0.534 -2.499  3.5264 1.01   735  31.7620
 sigma_1  4.013  3.441  4.6238 1.00  4655   0.1849
  time_2  0.547  0.407  0.6961 1.01   366   0.1369
  time_3 -0.220 -0.393 -0.0443 1.01   740   0.0992
```

`rhat` is the [Gelman-Rubin convergence diagnostic](https://www.rdocumentation.org/packages/coda/versions/0.19-3/topics/gelman.diag), `eff` is the [effective sample size](https://mc-stan.org/docs/2_18/reference-manual/effective-sample-size-section.html), and `ts_se` is the time-series standard error.

`plot_pars(fit)` can be used to inspect the posteriors and convergence of all parameters. See the documentation of `plot_pars()` for many other plotting options. Here, we plot just the (population-level) change points. They often have "strange" posterior distributions, highlighting the need for a computational approach:

```r
plot_pars(fit, regex_pars = "cp_")
```
![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_demo_combo.png)


## Tests and model comparison

We can test (joint) probabilities in the model using `hypothesis()` ([see more here](https://lindeloev.github.io/mcp/articles/comparison.html)). For example, what is the evidence (given priors) that the first change point is later than 25 against it being less than 25?

```r
hypothesis(fit, "cp_1 > 25")
```
```r
     hypothesis    mean     lower    upper         p       BF
1 cp_1 - 25 > 0 6.06081 -1.510267 14.01157 0.9442222 16.92829
```


For model comparisons, we can fit a null model and compare the predictive performance of the two models using (approximate) leave-one-out cross-validation ([see more here](https://lindeloev.github.io/mcp/articles/comparison.html)). Our null model omits the first plateau and change point, essentially testing the credence of that change point:

```r
# Define the model
segments_null = list(
  response ~ 1 + time,  # intercept (int_1) and slope (time_1)
  ~ 1 + time            # disjoined slope (int_2, time_1)
)

# Fit it
fit_null = mcp(segments_null, ex_demo)
```

Leveraging the power of `loo::loo`, we see that the two-change-points model is preferred (it is on top), but the `elpd_diff / se_diff` ratio ratio indicate that this preference is not very strong.
```r
fit$loo = loo(fit)
fit_null$loo = loo(fit_null)

loo::loo_compare(fit$loo, fit_null$loo)
```
```
       elpd_diff se_diff
model1  0.0       0.0   
model2 -7.8       4.7   
```



# Highlights from in-depth guides
The articles on the [mcp website](https://lindeloev.github.io/mcp) go in-depth with the functionality of `mcp`. Here is an executive summary, to give you a quick sense of what mcp can do.

[About mcp formulas and models](https://lindeloev.github.io/mcp/articles/formulas.html):
 * Parameter names are `int_i` (intercepts), `cp_i` (change points), `x_i` (slopes), `phi_i` (autocorrelation), and `sigma_*` (variance).
 * The change point model is basically an `ifelse` model.
 * Use `rel()` to specify that parameters are relative to those corresponding in the previous segments.
 * Generate data using `fit$simulate()`.

[Using priors](https://lindeloev.github.io/mcp/articles/priors.html):
 * See priors in `fit$prior`.
 * Set priors using `mcp(..., prior = list(cp_1 = "dnorm(0, 1)", cp_1 = "dunif(0, 45)")`.
 * Fix parameters to specific values using `cp_1 = 45`.
 * Share parameters between segments using `slope_1 = "slope_2"`.
 * Truncate priors using `T(lower, upper)`, e.g., `int_1 = "dnorm(0, 1) T(0, )"`. `mcp` applies this automatically to change point priors to enforce order restriction. This is true for [varying change points](https://lindeloev.github.io/mcp/articles/varying.html) too.
 * Do prior predictive checks using `mcp(segments, data, sample="prior")`.

[Varying change points](https://lindeloev.github.io/mcp/articles/varying.html):
 * Simulate varying change points using `fit$simulate()`.
 * Get posteriors using `ranef(fit)`.
 * Plot using `plot(fit, facet_by="my_group")` and `plot_pars(fit, pars = "varying", type = "dens_overlay", ncol = 3)`.
 * The default priors restrict varying change points to lie between the two adjacent change points.

`mcp` currently supports the following GLM:
 * `gaussian(link = "identity")` (default). See examples above and below.
 * `binomial(link = "logit")`. See [binomial change points in mcp](https://lindeloev.github.io/mcp/articles/binomial.html).
 * `bernoulli(link = "logit")`. See [binomial change points in mcp](https://lindeloev.github.io/mcp/articles/binomial.html).
 * `poisson(link = "log")`. See [Poisson change points in mcp](https://lindeloev.github.io/mcp/articles/poisson.html).

[Model comparison and hypothesis testing](https://lindeloev.github.io/mcp/articles/comparison.html):
 * Do Leave-One-Out Cross-Validation using `loo(fit)` and `loo::loo_compare(fit1$loo, fit2$loo)`.
 * Compute Savage-Dickey density rations using `hypothesis(fit, "cp_1 = 40")`.
 * Leverage directional and conditional tests to assess interval hypotheses (`hypothesis(fit, "cp_1 > 30 & cp_1 < 50")`), combined hypotheses (`hypothesis(fit, "cp_1 > 30 & int_1 > int_2")`), etc.

Modeling [variance](https://lindeloev.github.io/mcp/articles/variance.html) and [autoregression](https://lindeloev.github.io/mcp/articles/arma.html):
 * `~ sigma(1)` models an intercept change in variance. `~ sigma(0 + x)` models increasing/decreasing variance.
 * `~ ar(N)` models Nth order autoregression on residuals. `~ar(N, 0 + x)` models increasing/decreasing autocorrelation.
 * You can model anything for `sigma()` and `ar()`. For example, `~ x + sigma(1 + x + I(x^2))` models polynomial change in variance with `x` on top of a slope on the mean.
 * `sigma()` and `ar()` apply to varying change points too.

[Tips, tricks, and debugging](https://lindeloev.github.io/mcp/articles/debug.html)
 * Speed up fitting using `mcp(..., cores = 3)` / `options(mcp_cores = 3)`, and/or `mcp(..., adapt = 500)`.
 * Help convergence along using `mcp(..., inits = list(cp_1 = 20, int_2 = -3))`.
 * Most errors will be caused by circularly defined priors.



# Some examples
`mcp` aims to support a wide variety of models. Here are some example models for inspiration.


## Two plateaus
Find the single change point between two plateaus ([see how this data was generated](https://github.com/lindeloev/mcp/tree/master/data-raw/ex_plateaus.R))

```r
segments = list(
    y ~ 1,  # plateau (int_1)
    ~ 1     # plateau (int_2)
)
fit = mcp(segments, ex_plateaus, par_x = "x")
plot(fit)
```
![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_plateaus.png)


## Varying change points

Here, we find the single change point between two joined slopes. While the slopes are shared by all participants, the change point varies by `id`.

Read more about [varying change points in mcp](https://lindeloev.github.io/mcp/articles/varying.html) and [see how this data was generated](https://github.com/lindeloev/mcp/tree/master/data-raw/ex_varying.R).

```r
segments = list(
  y ~ 1 + x,          # intercept + slope
  1 + (1|id) ~ 0 + x  # joined slope, varying by id
)
fit = mcp(segments, ex_varying)
plot(fit, facet_by = "id")
```

![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_varying.png)

Summarise the varying change points using `ranef()` or plot them using `plot_pars(fit, "varying")`:

```r
ranef(fit)
```

```r
            name       mean      lower      upper     rhat  eff     ts_se
1 cp_1_id[Benny] -18.939028 -21.662758 -16.178849 1.000739 2539  4.801090
2  cp_1_id[Bill] -10.932586 -13.570255  -8.355125 1.001008  709 22.656037
3  cp_1_id[Cath]  -3.868473  -6.161151  -1.534219 1.000035  996 24.755440
4  cp_1_id[Erin]   6.298535   3.689802   9.089925 1.000215 5308  2.047966
5  cp_1_id[John]   9.742310   7.184306  12.258944 1.000451 1854  7.511643
6  cp_1_id[Rose]  17.699242  14.393830  21.048751 1.000152 4019  4.435384
```


## Generalized linear models
`mcp` supports Generalized Linear Modeling. See extended examples using [`binomial()`](https://lindeloev.github.io/mcp/articles/binomial.html) and [`poisson()`](https://lindeloev.github.io/mcp/articles/poisson.html). [See how this data was generated](https://github.com/lindeloev/mcp/tree/master/data-raw/ex_binomial.R).

Here is a binomial change point model with three segments. We plot the 95% HDI too:

```r
segments = list(
  y | trials(N) ~ 1,  # constant rate
  ~ 0 + x,            # joined changing rate
  ~ 1 + x             # disjoined changing rate
)
fit = mcp(segments, ex_binomial, family = binomial())
plot(fit, quantiles = TRUE)
```

![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_binomial.png)

Use `plot(fit, rate = FALSE)` if you want the points and fit lines on the original scale of `y` rather than divided by `N`.



## Time series
`mcp` allows for flexible time series analysis with autoregressive residuals of arbitrary order. Below, we model a change from a plateau to a slope with the same AR(2) residuals in both segments. We get  However, you can specify different AR(N) structures in each segment and do regression on the AR coefficients themselves using e.g., `ar(1, 1 + x)`. [Read more here](https://lindeloev.github.io/mcp/articles/arma.html).

```r
segments = list(
  price ~ 1 + ar(2),
  ~ 0 + time
)
fit = mcp(segments, ex_ar)
summary(fit)
```

```r
Population-level parameters:
    name    mean   lower   upper Rhat n.eff    ts_se
   ar1_1   0.463   0.346   0.579 1.00  1967 1.31e-02
   ar2_1   0.258   0.133   0.369 1.00  1772 1.84e-02
    cp_1 170.059 151.960 186.093 1.05   231 3.70e+03
   int_1  17.991  15.096  20.729 1.01   586 3.36e+01
 sigma_1   4.677   4.296   5.057 1.00  5060 7.08e-02
  time_2   0.456   0.370   0.549 1.01   485 4.13e-02
```


As of `mcp` v0.2, plotting does not yet visualize the autocorrelation. The autocorrelated nature of the residuals are better shown using lines than points, so let's tweak the default plot:

```r
plot_ar = plot(fit_ar) + geom_line()  # Add line
plot_ar$layers[[1]] = NULL  # Remove dots
plot_ar
```

![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_ar.png)



## Variance change and prediction intervals
You can model variance by adding a `sigma()` term to the formula. The inside `sigma()` can take everything that the formulas outside do. Read more in [the article on variance](https://lindeloev.github.io/mcp/articles/variance.html). The example below models two change points. The first is variance-only: variance abruptly increases and then declines linearly with `x`. The second change point is the stop of the variance-decline and the onset of a slope on the mean.

Effects on variance is best visualized using *prediction intervals*. See more in the documentation for `plot.mcpfit()`.

```r
segments = list(
  y ~ 1,
  ~ 0 + sigma(1 + x),
  ~ 0 + x
)
fit = mcp(segments, ex_variance, cores = 3, adapt = 5000, iter = 5000)
plot(fit, quantiles = TRUE, quantiles_type = "predict")
```

![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_variance.png)



## Quadratic and other exponentiations
Write exponents as `I(x^N)`. E.g., quadratic `I(x^2)`, cubic `I(x^3)`, or some other power function `I(x^1.5)`. The example below detects the onset of linear + quadratic growth. This is often called the BLQ model (Broken Line Quadratic) in nutrition research.

```r
segments = list(
  y ~ 1,
  ~ 0 + x + I(x^2)
)
fit = mcp(segments, ex_quadratic)
plot(fit)
```

![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_quadratic.png)




## Trigonometric and others
You can use `sin(x)`, `cos(x)`, and `tan(x)` to do trigonometry. This can be useful for seasonal trends and other periodic data. You can also do `exp(x)`, `abs(x)`, `log(x)`, and `sqrt(x)`, but beware that the two latter will currently fail in segment 2+. Raise an issue if you need this.

```r
segments = list(
  y ~ 1 + sin(x),
  ~ 0 + cos(x) + x
)

fit = mcp(segments, ex_trig)
plot(fit)
```

![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_trig.png)





## Using `rel()` and priors
Read more about [formula options](https://lindeloev.github.io/mcp/articles/formulas.html) and [priors](https://lindeloev.github.io/mcp/articles/priors.html) and [see how this data was generated](https://github.com/lindeloev/mcp/tree/master/data-raw/ex_rel_prior.R).

Here we find the two change points between three segments. The slope and intercept of segment 2 are parameterized relative to segment 1, i.e., modeling the *change* in intercept and slope since segment 1. So too with the second change point (`cp_2`) which is now the *distance* from `cp_1`. 

Some of the default priors are overwritten. The first intercept (`int_1`) is forced to be 10, the slopes are in segment 1 and 3 is shared. It is easy to see these effects in the `ex_rel_prior` dataset because they violate it somewhat. The first change point has to be at `x = 20` or later.

```r
segments = list(
  y ~ 1 + x,
  ~ rel(1) + rel(x),
  rel(1) ~ 0 + x
)

prior = list(
  int_1 = 10,  # Constant, not estimated
  x_3 = "x_1",  # shared slope in segment 1 and 3
  int_2 = "dnorm(0, 20)",
  cp_1 = "dunif(20, 50)"  # has to occur in this interval
)
fit = mcp(segments, ex_rel_prior, prior, iter = 10000)
plot(fit)
```

![](https://github.com/lindeloev/mcp/raw/master/man/figures/ex_fix_rel.png)

Comparing the summary to the fitted lines in the plot, we can see that `int_2` and `x_2` are relative values:
```r
summary(fit)
```

```r
Family: gaussian(link = 'identity')
Iterations: 30000 from 3 chains.
Segments:
  1: y ~ 1 + x
  2: y ~ 1 ~ rel(1) + rel(x)
  3: y ~ rel(1) ~ 0 + x

Population-level parameters:
    name  mean  lower upper Rhat n.eff   ts_se
    cp_1 23.26  20.00 26.11 1.00   308  256.74
    cp_2 51.85  46.89 56.44 1.00   485  316.37
   int_1 10.00  10.00 10.00  NaN     0    0.00
   int_2 -7.53 -21.19  8.52 1.00   256 7346.30
 sigma_1  9.68   8.32 11.07 1.00  7840    1.24
     x_1  1.59   1.28  1.86 1.01   151    4.10
     x_2 -3.29  -3.59 -2.98 1.02   299    1.79
     x_3  1.59   1.28  1.86 1.01   151    4.10
```




# Do much more
Don't be constrained by these simple `mcp` functions. `fit$samples` is a regular `mcmc.list` object and all methods apply. You can work with the MCMC samples just as you would with `brms`, `rstanarm`, `jags`, or other samplers using the always excellent `tidybayes`:

```r
library(tidybayes)

# Extract all parameters:
tidy_draws(fit$samples) %>%
  # tidybayes stuff here

# Extract some parameters:
fit$pars$model  # check out which parameters are inferred.
spread_draws(fit$samples, cp_1, cp_2, int_1, year_1) %>%
 # tidybayes stuff here
```
