data {
  int<lower=0> I;                         // number of predictors per item
  int<lower=1> K;                         // number of items available to be ranked
  int<lower=1> M;                         // number of (partial) rankings
  int<lower=1> N;                         // number of observations
  int<lower=1,upper=K> a[M];              // number of alternatives available per ranking
  int<lower=1,upper=K> t[M];              // number of alternatives ranked per ranking
  matrix[K,I] X;                          // predictors
  int<lower=1,upper=K> y[N];              // observations
  real<lower=0> global_scale;             // global scale for the hs prior
  real<lower=0> slab_scale;               // slab scale for the hs prior
}

parameters {
  real<lower=0> sigma;                    // scale of linear predictor error
  vector[I] beta_raw;                     // raw coefficient values
  real<lower=0> tau;                      // global hs shrinkage
  vector<lower=0>[I] lambda;              // local hs shrinkage
  real<lower=0> c_raw;                    // raw slab scale
  vector[K] alpha_raw;                    // raw worth
}

transformed parameters {
  real<lower=0> c = slab_scale * sqrt(c_raw); // slab scale
  vector<lower=0>[I] lambda_tilde =
    sqrt(c^2 * square(lambda) ./ (c^2 + tau^2 * square(lambda)));
                                          // truncated local shrinkage
  vector[I] beta = beta_raw .* lambda_tilde * tau;
                                          // regression coefficients
  vector[I > 0 ? K : 0] f;                // linear predictor
  vector[K] alpha;                        // log worth
  if (I > 0) {
    f = X * beta;
    alpha = f + sigma * alpha_raw;
  } else {
    alpha = sigma * alpha_raw;
  }
}

model {
  // Hierarchical prior defaults from rstanarm
  int n = 1;
  sigma ~ std_normal();
  beta_raw ~ std_normal();
  tau ~ student_t(1, 0, global_scale * sigma);
  lambda ~ student_t(1, 0, 1);
  c_raw ~ inv_gamma(2, 2);
  alpha_raw ~ std_normal();
  // Random standard Gumbel utility is implied by multi-logit.
  for (m in 1:M) {
    // Iterate over each level of the ranking to explode the logit.
    for (i in 1:t[m]) {
      1 ~ categorical_logit(alpha[segment(y, n + i - 1, a[m] - i + 1)]);
    }
    n += a[m];
  }
}
