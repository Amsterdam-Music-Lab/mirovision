functions {
  // Partial sum function for parallelisation
  real partial_sum_denominator(array[,] int wmm, int start, int end,
                               array[] int nn, vector beta) {
    real log_lik = 0;
    for (m in wmm) {
      log_lik += m[1] * log_sum_exp(beta[segment(nn, m[2], m[3])]);
    }
    return log_lik;
  }
}

data {
  int<lower=1> I;                              // number of voting configs
  int<lower=1> J;                              // number of countries
  int<lower=1> M;                              // number of configuration slots
  int<lower=1> N;                              // number of contestants
  array[N] int<lower=1, upper=J>  jj;          // country for contestant n
  array[M] int<lower=1, upper=N>  nn;          // contestant for slot m
  array[I] int<lower=1, upper=J> NN;           // no. contestants per config
  array[I] int<lower=1, upper=2 * J> ww;       // number of uses per config
  array[N] int<lower=0, upper=4 * 12 * J> xx;  // total scores per country
}

transformed data {
  array[I, 3] int<lower=1> wmm;
  vector[N] xx_real = to_vector(xx);
  wmm[1] = {58 * ww[1], 1, NN[1]}; // 58 = sum(c(1:8, 10, 12))
  for (i in 2:I) {
    wmm[i] = {58 * ww[i], wmm[i - 1, 2] + wmm[i - 1, 3], NN[i]};
  }
}

parameters {
  real<lower=0> sigma_country;     // scale of quality among countries
  real<lower=0> sigma_contestant;  // scale of residual contestant quality
  vector[J] beta_country_raw;      // standardised country quality
  vector[N] beta_contestant_raw;   // standardised releative contestant quality
}

transformed parameters {
  vector[J] beta_country = sigma_country * beta_country_raw;
  vector[N] beta_contestant =
    beta_country[jj] + sigma_contestant * beta_contestant_raw;
}

model {
  // Priors
  sigma_country ~ exponential(1);
  sigma_contestant ~ exponential(1);
  beta_country_raw ~ std_normal();
  beta_contestant_raw ~ std_normal();
  // Numerators
  target += dot_product(xx_real, beta_contestant);
  // Denominators
  target += -reduce_sum(partial_sum_denominator, wmm, 1, nn, beta_contestant);
}

generated quantities {
  real sigma_beta = sqrt(square(sigma_country) + square(sigma_contestant));
  array[J] real country_prior = normal_rng(zeros_vector(J), sigma_country);
  array[N] real contestant_prior =
    normal_rng(country_prior[jj], sigma_contestant);
}
