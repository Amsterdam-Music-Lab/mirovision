functions {
  real log_normaliser(vector theta, real partial, int depth,
                      vector alpha) {
    if (depth > size(alpha)) {
      return partial;
    } else if (size(theta) == 1) {
      return fma(alpha[depth], theta[1], partial);
    } else {
      int N = size(theta);
      vector[N] partials;
      for (n in 1:N) {
        vector[N - 1] reduced_theta;
        if (n == 1) {
          reduced_theta = theta[2:];
        } else if (n == N) {
          reduced_theta = theta[:(N - 1)];
        } else {
          reduced_theta = append_row(theta[:(n - 1)], theta[(n + 1):]);
        }
        partials[n] =
          log_normaliser(
            reduced_theta,
            fma(alpha[depth], theta[n], partial),
            depth + 1,
            alpha
          );
      }
      return log_sum_exp(partials);
    }
  }

  real partial_kl(vector theta, real lnum, real lden, int depth, vector alpha) {
    if (depth > size(alpha)) {
      return exp(lnum) * lden;
    } else if (size(theta) == 1) {
      real log_num = fma(alpha[depth], theta[1], lnum);
      real log_den = fma(alpha[depth], theta[1], lden);
      return exp(log_num) * log_den;
    } else {
      int N = size(theta);
      vector[N] partials;
      for (n in 1:N) {
        vector[N - 1] reduced_theta;
        if (n == 1) {
          reduced_theta = theta[2:N];
        } else if (n == N) {
          reduced_theta = theta[1:(N - 1)];
        } else {
          reduced_theta = append_row(theta[:(n - 1)], theta[(n + 1):]);
        }
        partials[n] =
          partial_kl(
            reduced_theta,
            fma(alpha[depth], theta[n], lnum),
            log_sum_exp(alpha[depth] * theta) + lden,
            depth + 1,
            alpha
          );
      }
      return sum(partials);
    }
  }
}

data {
  int<lower=1> K;
  int<lower=1, upper=10> I;
}

transformed data {
  vector<lower=0>[10] alpha = [12, 10, 8, 7, 6, 5, 4, 3, 2, 1]' / 12;
}

generated quantities {
  array[I] real sigma = exponential_rng(ones_vector(I));
  vector[I] kl_exploded;
  vector[I] kl_softmax;
  for (i in 1:I) {
    vector[K] theta = to_vector(normal_rng(zeros_vector(K), sigma[i]));
    real log_rasch_normaliser = log_normaliser(theta, 0, 1, alpha[1:i]);
    real log_softmax_normaliser = 0;
    for (j in 1:i) log_softmax_normaliser += log_sum_exp(alpha[j] * theta);
    kl_exploded[i] =
      partial_kl(theta, 0, 0, 1, alpha[1:i]) / exp(log_rasch_normaliser)
      - log_rasch_normaliser;
    kl_softmax[i] = log_softmax_normaliser - log_rasch_normaliser;
  }
}
