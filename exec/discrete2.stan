# GLM for a discrete outcome with Gaussian or t priors
functions {
  # Combine intercept and coefficients into a vector or return coefficients
  # if no intercept. 
  #
  # @param alpha array of size 0 or 1 depending on if model has intercept
  # @param theta vector of coefficients (not including intercept) of size 
  #   K-1 or K depending on if model has intercept
  # @param K number of columns of the predictor matrix X 
  # @return if the model has an intercept then the function combines alpha
  #   and theta into a vector. if the model doesn't have an intercept then 
  #   theta itself is returned
  vector coefficient_vector(real[] alpha, vector theta, int K) {
    vector[K] beta;
    int S;
    S <- size(alpha);
    if (S == 0) {
      if (K != rows(theta)) {
        reject("Dimension mismatch");
      }
      return theta;
    }
    else 
      if (K != 1 + rows(theta)) {
        reject("Dimension mismatch");
      }
      beta[1] <- alpha[1];
      for (k in 2:K) 
        beta[k] <- theta[k-1];
      return beta;
  }
}
data {
  # dimensions
  int<lower=1> N; # number of observations
  int<lower=1> K; # number of predictors
  
  # data
  matrix[N,K]  X; # predictor matrix
  int<lower=0> y[N]; # discrete outcome
  
  # intercept
  int<lower=0,upper=1> has_intercept; # 1 = yes
  
  # likelihood
  int<lower=1> family; # 1 = binomial, other = poisson
  
  # link function from location to linear predictor
  int<lower=1,upper=5> link; # values depend on family
  
  # weights
  int<lower=0,upper=1> has_weights; # 0 = No (weights is a ones vector), 1 = Yes
  vector[N] weights;
  
  # offset
  int<lower=0,upper=1> has_offset;  # 0 = No (offset is a zero vector), 1 = Yes
  vector[N] offset;
  
  # prior family
  int<lower=1,upper=2> prior_dist; # 1 = normal, 2 = student_t
  int<lower=1,upper=2> prior_dist_for_intercept; # 1 = normal, 2 = student_t
  
  # hyperparameter values
  vector<lower=0>[K - has_intercept] prior_scale;
  real<lower=0> prior_scale_for_intercept;
  vector[K - has_intercept] prior_mean;
  real prior_mean_for_intercept;
  vector<lower=0>[K - has_intercept] prior_df;
  real<lower=0> prior_df_for_intercept;
}
parameters {
  real alpha[has_intercept];
  vector[K - has_intercept] theta;
}
model {
  vector[N] eta;
  vector[K] beta;
  
  beta <- coefficient_vector(alpha, theta, K);  
  
  eta <- X * beta;
  if (has_offset == 1) 
    eta <- eta + offset;
  
  if (has_weights == 0) { # unweighted log-likelihoods
    if (family == 1) {    # bernoulli case
      if (link == 1) y ~ bernoulli_logit(eta);
      else {
        vector[N] pi;
        if (link == 2)      for(n in 1:N) pi[n] <- Phi_approx(eta[n]);
        else if (link == 3) for(n in 1:N) pi[n] <- cauchy_cdf(eta[n], 0.0, 1.0);
        else if (link == 4) for(n in 1:N) pi[n] <- exp(eta[n]); # may be > 1
        else if (link == 5) for(n in 1:N) pi[n] <- inv_cloglog(eta[n]);
        y ~ bernoulli(pi);
      }
    }
    else { # poisson case
      y ~ poisson_log(eta);
    }
  }
  else { # weighted log-likelihoods
    vector[N] summands;
    if (family == 1) { # bernoulli case
      if (link == 1) {
        for (n in 1:N) 
          summands[n] <- bernoulli_logit_log(y[n], eta[n]);
      }
      else if (link == 2) {
        for (n in 1:N) 
          summands[n] <- bernoulli_log(y[n], Phi(eta[n])) ;
      }
      else if (link == 3) {
        for (n in 1:N) 
          summands[n] <- bernoulli_log(y[n], cauchy_cdf(eta[n], 0.0, 1.0));
      }
      else if (link == 4) {
        for (n in 1:N) 
          summands[n] <- bernoulli_log(y[n], exp(eta[n]));
      }
      else if (link == 5) {
        for (n in 1:N) 
          summands[n] <- bernoulli_log(y[n], inv_cloglog(eta[n]));
      }
    }
    else { # poisson case
      for (n in 1:N) 
        summands[n] <- poisson_log_log(y[n], eta[n]);
    }
    increment_log_prob(dot_product(weights, summands));
  }
  
  # log-priors
  if (prior_dist == 1) { # normal
    theta ~ normal(prior_mean, prior_scale);  
  } 
  else { # student_t
    theta ~ student_t(prior_df, prior_mean, prior_scale);
  }
  if (has_intercept) {
    if (prior_dist_for_intercept == 1) { # normal
      alpha ~ normal(prior_mean_for_intercept, prior_scale_for_intercept);
    }
    else { # student_t
      alpha ~ student_t(prior_df_for_intercept, prior_mean_for_intercept, 
                        prior_scale_for_intercept);
    }
  }
}
generated quantities {
  vector[K] beta;
  beta <- coefficient_vector(alpha, theta, K);  
}