data {
  int<lower=1> N;
  int X[N];
  int numZeros;
  real L[N];
}
parameters {
  real<lower=0.000001> n_nbMean; // Noise negtive binomial mean rate parameter
  real<lower=0.1> n_nbDisp; //Noise negative binomial disp rate parameter
  real<lower=0.000001,upper=0.1> r;  // Mixture proportion
  real<lower=5> nbMean; // neg binomial mean parameter
  real<lower=0.1> nbDisp; // neg binomial dispersion parameter
}
model {
   // Priors:
   r ~ beta(1,10);
   nbDisp ~ lognormal(log(3),log(2));
   n_nbMean ~ lognormal(log(1.075),log(1.1));
   n_nbDisp ~ lognormal(log(1.1),log(1.1));
   nbMean ~ lognormal(log(100),log(3));

   // Likelihoods:
   for(i in 1:N) {
   //print out L, check to see the L are in the right order, print out dispersion in the old model and plug in as a constant, not dividing the snbDisp by anything.
      real sn_nbDisp = n_nbDisp; 
      real sn_nbMean = n_nbMean * L[i];
      real snbDisp = nbDisp; 
      real snbMean = nbMean * L[i];
      //target+= log_sum_exp(log(r)+poisson_lpmf(X[i]|slambda)-log(1-exp(-slambda)),
      //                     log(1-r)+neg_binomial_2_lpmf(X[i]|snbMean,snbDisp)-log(1-pow((snbDisp/(snbDisp+snbMean)),snbDisp)));
      //target+= log_sum_exp(log(1-r)+poisson_lpmf(X[i]|slambda),log(r)+neg_binomial_2_lpmf(X[i]|snbMean,snbDisp))-log_diff_exp(log(1),log_sum_exp((log(1-r)+log(exp(-slambda))),(log(r)+snbDisp*(log(snbDisp)-log_sum_exp(log(snbDisp),log(snbMean))))));
      //target+= log_sum_exp(log(1-r)+neg_binomial_2_lpmf(X[i]|sn_nbMean,sn_nbDisp),log(r)+neg_binomial_2_lpmf(X[i]|snbMean,snbDisp))-log_diff_exp(log(1),log_sum_exp(log(1-r)+sn_nbDisp*(log(log(sn_nbDisp)-log_sum_exp(log(sn_nbDisp),log(sn_nbMean)))),log(r)+snbDisp*(log(snbDisp)-log_sum_exp(log(snbMean),log(snbDisp)))));
      target+= log_sum_exp(log(1-r)+neg_binomial_2_lpmf(X[i]|sn_nbMean,sn_nbDisp),log(r)+neg_binomial_2_lpmf(X[i]|snbMean,snbDisp))-log_diff_exp(log(1),log_sum_exp(log(1-r)+sn_nbDisp*(log(sn_nbDisp)-log_sum_exp(log(sn_nbDisp),log(sn_nbMean))),log(r)+snbDisp*(log(snbDisp)-log_sum_exp(log(snbMean),log(snbDisp)))));
      }

   // This is an optimization (for speed), since there will be massive numbers
   // of zeros (cells without the guide) and they all have the same likelihood:
   //target+=numZeros*log_sum_exp(log(r)+poisson_lpmf(0|lambda),
   //                        log(1-r)+neg_binomial_2_lpmf(0|nbMean,nbDisp));
}
generated quantities {
   real<lower=0,upper=1> PZi[N];
   real likeli_n_negbin[N];
   real likeli_negbin[N];
   real lambdasum=0;
   //real nbsum=0;
   for(i in 1:N) {
      real sn_nbDisp = n_nbDisp; // * L[i];
      real sn_nbMean = n_nbMean * L[i];
      real snbDisp = nbDisp; // sqrt(L[i]);
      real snbMean = nbMean * L[i];
      real LP0=log(1-r)+neg_binomial_2_lpmf(X[i]|sn_nbMean,sn_nbDisp);
      real LP1=log(r)+neg_binomial_2_lpmf(X[i]|snbMean,snbDisp);
      //real LP0=log(r)+poisson_lpmf(X[i]|slambda)-log(1-exp(-slambda));
      //real LP1=log(1-r)+neg_binomial_2_lpmf(X[i]|snbMean,snbDisp)-log(1-pow((snbDisp/(snbDisp+snbMean)),snbDisp));
      PZi[i]=exp(LP1-log_sum_exp(LP0,LP1));
      likeli_n_negbin[i] = LP0-log(1-r);
      likeli_negbin[i] = LP1-log(r);
   }
   //for(i in 1:1000000) {
   //lambdasum+=poisson_lpmf(X[i]|lambda)-log(1-exp(-lambda));
   //nbsum+=neg_binomial_2_lpmf(X[i]|nbMean,nbDisp)-log(1-pow((nbDisp/(nbDisp+nbMean)),nbDisp));
   //}
}

