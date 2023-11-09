functions {
  // Log likelihood under a Rasch partial-credit model
  real pcm_lpmf(int x, vector alpha, vector theta_raw) {
    int K = num_elements(theta_raw);
    vector[K + 1] theta = append_row(0, cumulative_sum(alpha .* theta_raw));
    return categorical_logit_lpmf(x + 1 | theta);
  }

  // Random responses under a Rasch partial-credit model
  int pcm_rng(vector alpha, vector theta_raw) {
    int K = num_elements(theta_raw);
    vector[K + 1] theta = append_row(0, cumulative_sum(alpha .* theta_raw));
    return categorical_logit_rng(theta) - 1;
  }

  // Partial sum function for parallelisation
  real partial_sum_eurovision(array[] int xx, int start, int end,
                              array[] int ii, array[] int nn,
                              vector alpha, vector beta, matrix delta) {
    real log_lik = 0;
    for (m in start:end) {
      int i = ii[m];
      int k = xx[m - start + 1];
      int n = nn[m];
      log_lik += pcm_lpmf(k | alpha, beta[n] - delta[:, i]);
    }
    return log_lik;
  }
}

data {
  int<lower=1> I;                      // number of shows
  int<lower=1> J;                      // number of countries
  int<lower=1> M;                      // number of observations
  int<lower=1> N;                      // number of contestants
  array[M] int<lower=1, upper=I> ii;   // show for observation m
  array[N] int<lower=1, upper=J> jj;   // country for contestant n
  array[M] int<lower=1, upper=N> nn;   // contestant for observation m
  array[M] int<lower=0, upper=25> xx;  // observations (scores)
}

transformed data {
  int<lower=1> K = 25;                 // number of thresholds
}

parameters {
  vector[K] mu;                     // mean score thresholds
  real<lower=0> sigma_country;      // scale of quality among countries
  vector<lower=0>[K] sigma_delta;   // scales of score thresholds
  cholesky_factor_corr[K] L_delta;  // threshold correlation
  vector<lower=0>[K] alpha;         // threshold discrimination
  vector[J] beta_country_raw;       // standardised country quality
  vector[N] beta_contestant_raw;    // standardised relative contestant quality
  matrix[K, I] delta_raw;           // whitened score thresholds per show
}

transformed parameters {
  vector[J] beta_country = sigma_country * beta_country_raw;
  vector[N] beta_contestant = beta_country[jj] + beta_contestant_raw;
  matrix[K, I] delta =
    rep_matrix(mu, I) + diag_pre_multiply(sigma_delta, L_delta) * delta_raw;
}

model {
  mu ~ std_normal();
  sigma_country ~ exponential(1);
  sigma_delta ~ exponential(1);
  L_delta ~ lkj_corr_cholesky(2);
  alpha ~ exponential(1);
  beta_country_raw ~ std_normal();
  beta_contestant_raw ~ std_normal();
  to_vector(delta_raw) ~ std_normal();
  target +=
    reduce_sum(
      partial_sum_eurovision, xx, 1,
      ii, nn, alpha, beta_contestant, delta
    );
}

generated quantities {
  array[J] real country_prior = normal_rng(zeros_vector(J), sigma_country);
  array[N] real contestant_prior = normal_rng(country_prior[jj], 1);
  vector[K] scores = 12 * cumulative_sum(alpha) / sum(alpha);
}
