data {
  int<lower=0> I;                         // number of predictors per item
  int<lower=1> K;                         // number of items available to be ranked
  int<lower=1> M;                         // number of (partial) rankings
  int<lower=1> N;                         // number of observations
  int<lower=1,upper=K> a[M];              // number of alternatives available per ranking
  int<lower=1,upper=K> t[M];              // number of alternatives ranked per ranking
  matrix[K,I] X;                          // predictors
  int<lower=1,upper=K> y[N];              // observations
}

parameters {
  real<lower=0> sigma;                    // scale of linear predictor error
  vector[I] beta;                         // raw coefficient values
  vector[K] alpha_raw;                    // raw worth
}

transformed parameters {
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
  beta ~ std_normal();
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
