functions {
  // Partial sum function for parallelisation
  real partial_sum_lpmf(array[] int ii, int start, int end,
                        array[] int kk, array[] int mm, array[] int nn,
                        vector beta) {
    real log_lik = 0;
    for (i in ii) {
      int K = kk[i];
      int n_pairs = (K * (K - 1)) %/% 2;
      vector[K] beta_i = beta[nn[(mm[i] + 1):(mm[i] + K)]];
      // vector[n_pairs] pairs;
      // int k = 0;
      // for (k1 in 1:(K - 1)) {
      //   for (k2 in (k1 + 1):K) {
      //     k += 1;
      //     pairs[k] = beta_i[k1] + beta_i[k2];
      //   }
      // }
      // log_lik += beta_i[1] + beta_i[2];
      // log_lik -= log_sum_exp(pairs);
      for (k1 in 1:10) {
        for (k2 in (k1 + 1):K) {
          log_lik += bernoulli_logit_lupmf(1 | beta_i[k1] - beta_i[k2]);
        }
      }
    }
    return log_lik;
  }
}

data {
  int<lower=1> I;                        // number of votes
  int<lower=1> J;                        // number of countries
  int<lower=1> M;                        // number of observations
  int<lower=1> N;                        // number of contestants
  array[N] int<lower=1, upper=J> jj;     // country for contestant n
  array[I] int<lower=10, upper=N> kk;    // number of contestants for vote i
  array[M] int<lower=1, upper=N> nn;     // contestant for observation m
                                         //   ordered by vote and desc. rank
}

transformed data {
  array[I] int<lower=0, upper=M> mm =
    append_array({0}, cumulative_sum(kk)[1:(I - 1)]);
}

parameters {
  real<lower=0> sigma_country;      // scale of quality among countries
  real<lower=0> sigma_contestant;   // scale of residual contestant quality
  vector[J] beta_country_raw;       // standardised country quality
  vector[N] beta_contestant_raw;    // standardised releative contestant quality
}

transformed parameters {
  vector[J] beta_country = sigma_country * beta_country_raw;
  vector[N] beta_contestant =
    beta_country[jj] + sigma_contestant * beta_contestant_raw;
}

model {
  sigma_country ~ exponential(1);
  sigma_contestant ~ exponential(1);
  beta_country_raw ~ std_normal();
  beta_contestant_raw ~ std_normal();
  target +=
    reduce_sum(
      partial_sum_lupmf, linspaced_int_array(I, 1, I), 1,
      kk, mm, nn,
      beta_contestant);
}

generated quantities {
  real sigma_beta = sqrt(square(sigma_country) + square(sigma_contestant));
  array[J] real country_prior = normal_rng(zeros_vector(J), sigma_country);
  array[N] real contestant_prior =
    normal_rng(country_prior[jj], sigma_contestant);
}
