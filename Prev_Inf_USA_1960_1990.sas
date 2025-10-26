libname memoire "/home/u64001580/Économétrie appliquée/MemoireS2";

/* We import data for the US  */
PROC IMPORT datafile = "/home/u64001580/Économétrie appliquée/MemoireS2/USA_M2SL.csv"
   	dbms = csv 
    out = memoire.USA_M2;
    getnames = yes;
RUN;

PROC IMPORT datafile = "/home/u64001580/Économétrie appliquée/MemoireS2/USA_M2V.csv"
	dbms = csv 
    out = memoire.USA_M2V;
    getnames = yes;
RUN;

PROC IMPORT datafile = "/home/u64001580/Économétrie appliquée/MemoireS2/USA_GDP.csv"
	dbms = csv 
    out = memoire.USA_GDP;
    getnames = yes;
RUN;

PROC IMPORT datafile = "/home/u64001580/Économétrie appliquée/MemoireS2/USA_GDPC1.csv"
	dbms = csv 
    out = memoire.USA_RGDP;
    getnames = yes;
RUN;

/* We can merge the tables into one */
DATA memoire.USA_ALL;
    merge memoire.USA_M2
          memoire.USA_M2V
          memoire.USA_GDP
          memoire.USA_RGDP;
    by observation_date;
    where observation_date >= '01JAN1960'd and observation_date < '01JAN1990'd;
RUN;

/* We can plot these data */
PROC SGPLOT data=memoire.USA_ALL;
    series x=observation_date y=M2SL;
    xaxis label="Date";
    yaxis label="Billions of Dollars";
    title "M2";
RUN;

PROC SGPLOT data=memoire.USA_ALL;
    series x=observation_date y=M2V;
    xaxis label="Date";
    yaxis label="Ratio";
    title "Velocity of M2 Money Stock";
RUN;

PROC SGPLOT data=memoire.USA_ALL;
    series x=observation_date y=GDPC1;
    xaxis label="Date";
    yaxis label="Billions of Chained 2017 Dollars";
    title "Real Gross Domestic Product";
RUN;


/* P and P* on the same plot */
DATA memoire.USA_ALL;
    set memoire.USA_ALL;
    GDPDEF = GDP / GDPC1;
	P = GDPDEF;
	M = M2SL;
	V = M2V;
	Q = GDPC1;
RUN;

PROC EXPAND data=memoire.USA_ALL out=memoire.USA_ALL_Ps;
    id observation_date;
    convert Q = Q_star / transformout=(movave 4);
RUN;

PROC MEANS data=memoire.USA_ALL_Ps noprint;
    var V;
    output out=USA_mean_V mean=V_star;
RUN;

DATA memoire.USA_ALL_Ps;
    if _n_ = 1 then set USA_mean_V;
    set memoire.USA_ALL_Ps;

    P_star = (M*V_star)/Q_star;
RUN;

PROC SGPLOT data=memoire.USA_ALL_Ps;
    series x=observation_date y=P / lineattrs=(color=blue) 
        legendlabel="Current price level (P)";

    series x=observation_date y=P_star / lineattrs=(color=red pattern=shortdash) 
        legendlabel="Long-run equilibrium price level (P*)";

    xaxis label="Date";
    yaxis label="(Ratio Scale)";
    title "Evolution of p and p*";
RUN;

/* Inflation plot */
DATA memoire.USA_ALL_Ps;
    set memoire.USA_ALL_Ps;
    lag4_P = lag4(P);
	inflation = 100 * (P - lag4_P) / lag4_P;
RUN;

PROC SGPLOT data=memoire.USA_ALL_Ps;
    series x=observation_date y=inflation / lineattrs=(color=green);     
    xaxis label="Date";
    yaxis label="(Percent)";
    title "Evolution of inflation";
RUN;

/* Step 1 - Preparation of the data */
DATA memoire.USA_ALL_Ps;
    set memoire.USA_ALL_Ps;
    p      = log(P);
    m      = log(M);
    v      = log(V);
    q      = log(Q);
    
    v_star = log(v_star);
    q_star = log(q_star);
    p_star = log(p_star);

    dif_ps = dif(p_star);
    dif_p = dif(p);
    dif_m = dif(m);
    dif_v = dif(v);
    dif_q = dif(q);
RUN;


/* Step 2 – Test the integration of the series */
PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=p_star stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=dif_ps stationarity=(adf=5);
RUN;

PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=p stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=dif_p stationarity=(adf=5);
RUN;

PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=m stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=dif_m stationarity=(adf=5);
RUN;

PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=q stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=dif_q stationarity=(adf=5);
RUN;

PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=v stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.USA_ALL_Ps;
    identify var=dif_v stationarity=(adf=5);
RUN;


/* Step 3 – Co-integration test */
PROC AUTOREG data=memoire.USA_ALL_Ps;
    model p = p_star / stationarity=(adf=5);
    output out=resultats residual=residus;
RUN;

PROC ARIMA data=resultats;
    identify var=residus stationarity=(adf=5);
RUN;


/* Step 4 – Estimate the error-corrected model (ECM) */
DATA memoire.USA_ECM;
    set memoire.USA_ALL_Ps;
    ECM = p - p_star;
    lag_ECM = lag(ECM);

    lag_dif_p = lag(dif_p);
    lag2_dif_p = lag2(dif_p);
	lag3_dif_p = lag3(dif_p);
	
    lag_dif_m = lag(dif_m);
    lag2_dif_m = lag2(dif_m);
	lag3_dif_m = lag3(dif_m);
	
    lag_dif_q = lag(dif_q);
    lag2_dif_q = lag2(dif_q);
	lag3_dif_q = lag3(dif_q);
	
    lag_dif_v = lag(dif_v);
    lag2_dif_v = lag2(dif_v);
    lag3_dif_v = lag3(dif_v);
RUN;

PROC MODEL data=memoire.USA_ECM;
    dif_p = gamma*lag_ECM
          + delta1*lag_dif_p + delta2*lag2_dif_p + delta3*lag3_dif_p
          + theta1*lag_dif_m + theta2*lag2_dif_m + theta3*lag3_dif_m
          + phi1*lag_dif_q + phi2*lag2_dif_q + phi3*lag3_dif_q
          + psi1*lag_dif_v + psi2*lag2_dif_v + psi3*lag3_dif_v;

    id observation_date;
    fit dif_p / out=memoire.pred_ecm outest=memoire.estimations outpredict;
RUN;


/* Step 5 – Evaluate in-sample performance */
/* Comparison of estimated values to p observed in the estimation sample */
DATA _null_;
    set memoire.estimations;
    call symputx('gamma', gamma);
    call symputx('delta1', delta1);
    call symputx('delta2', delta2);
    call symputx('delta3', delta3);
    call symputx('theta1', theta1);
    call symputx('theta2', theta2);
    call symputx('theta3', theta3);
    call symputx('phi1', phi1);
    call symputx('phi2', phi2);
    call symputx('phi3', phi3);
    call symputx('psi1', psi1);
    call symputx('psi2', psi2);
    call symputx('psi3', psi3);
RUN;

DATA memoire.pred_ecm;
    set memoire.USA_ECM;
    predicted_dif_p = 
        &gamma * lag_ECM +
        &delta1 * lag_dif_p + &delta2 * lag2_dif_p + &delta3 * lag3_dif_p +
        &theta1 * lag_dif_m + &theta2 * lag2_dif_m + &theta3 * lag3_dif_m +
        &phi1 * lag_dif_q + &phi2 * lag2_dif_q + &phi3 * lag3_dif_q +
        &psi1 * lag_dif_v + &psi2 * lag2_dif_v + &psi3 * lag3_dif_v;
RUN;

PROC SGPLOT data=memoire.pred_ecm;
    series x=observation_date y=dif_p / lineattrs=(color=blue) legendlabel="Observed Δp";
    series x=observation_date y=predicted_dif_p / lineattrs=(color=red pattern=shortdash) legendlabel="Predicted Δp (ECM)";
    xaxis label="Date";
    yaxis label="dif_p";
    title "Comparison between observed and predicted dif_p (in-sample)";
RUN;

/* Study of R2 */
PROC MEANS data=memoire.pred_ecm noprint;
    var dif_p;
    output out=stats mean=mean_dif_p;
RUN;

DATA memoire.R2_calc;
    if _n_ = 1 then set stats;
    set memoire.pred_ecm;
    sq_total = (dif_p - mean_dif_p)**2;
    sq_resid = (dif_p - predicted_dif_p)**2;
RUN;

PROC MEANS data=memoire.R2_calc noprint;
    var sq_total sq_resid;
    output out=R2_result sum=sst ssr;
RUN;

DATA R2_final;
    set R2_result;
    R2 = 1 - (ssr / sst);
RUN;

PROC PRINT data=R2_final label noobs;
    var R2;
    label R2 = "R2 of the ECM model (in-sample)";
    title "Determination coefficient R2 of the ECM model";
RUN;


/* Residue analysis */
DATA memoire.residus_ECM;
    set memoire.pred_ecm;
    erreur = dif_p - predicted_dif_p;
RUN;

PROC ARIMA data=memoire.residus_ECM;
    identify var=erreur stationarity=(adf=5);
RUN;

PROC UNIVARIATE data=memoire.residus_ECM normal;
    var erreur;
    histogram erreur / normal(mu=est sigma=est);
    inset mean std skewness kurtosis / position=ne;
RUN;

PROC UNIVARIATE data=memoire.residus_ECM normal;
    var erreur;
    qqplot erreur / normal(mu=est sigma=est);
RUN;


/* Step 6 – Perform out-of-sample previsions */
/* Define the estimation sample */
DATA estimation prediction;
    set memoire.USA_ECM;
    if observation_date <= '01JAN1985'd then output estimation;
    else if observation_date > '01JAN1985'd then output prediction;
RUN;

/* Estimate ECM model on data up to 1985 */
PROC MODEL data=estimation;
    dif_p = gamma*lag_ECM
          + delta1*lag_dif_p + delta2*lag2_dif_p + delta3*lag3_dif_p
          + theta1*lag_dif_m + theta2*lag2_dif_m + theta3*lag3_dif_m
          + phi1*lag_dif_q + phi2*lag2_dif_q + phi3*lag3_dif_q
          + psi1*lag_dif_v + psi2*lag2_dif_v + psi3*lag3_dif_v;

    id observation_date;
    fit dif_p / out=ecm_estimation outest=ecm_params;
RUN;

/* Generate out-of-sample previsions */
DATA _null_;
    set ecm_params;
    call symputx('gamma', gamma);
    call symputx('delta1', delta1); call symputx('delta2', delta2); call symputx('delta3', delta3);
    call symputx('theta1', theta1); call symputx('theta2', theta2); call symputx('theta3', theta3);
    call symputx('phi1', phi1);     call symputx('phi2', phi2);     call symputx('phi3', phi3);
    call symputx('psi1', psi1);     call symputx('psi2', psi2);     call symputx('psi3', psi3);
RUN;

DATA prediction_forecast;
    set prediction;
    predicted_dif_p = 
        &gamma * lag_ECM +
        &delta1 * lag_dif_p + &delta2 * lag2_dif_p + &delta3 * lag3_dif_p +
        &theta1 * lag_dif_m + &theta2 * lag2_dif_m + &theta3 * lag3_dif_m +
        &phi1 * lag_dif_q + &phi2 * lag2_dif_q + &phi3 * lag3_dif_q +
        &psi1 * lag_dif_v + &psi2 * lag2_dif_v + &psi3 * lag3_dif_v;
RUN;

/* Compare to reality + RMSFE */
PROC SGPLOT data=prediction_forecast;
    series x=observation_date y=dif_p / lineattrs=(color=blue) legendlabel="Observed p-p_star";
    series x=observation_date y=predicted_dif_p / lineattrs=(color=red pattern=shortdash) legendlabel="Predicted Δp (ECM)";
    xaxis label="Date";
    yaxis label="dif_p";
    title "Out-of-sample forecast: dif_p (ECM)";
RUN;

DATA ecm_rmsfe;
    set prediction_forecast;
    erreur = dif_p - predicted_dif_p;
    erreur2 = erreur**2;
RUN;

PROC MEANS data=ecm_rmsfe noprint;
    var erreur2;
    output out=ecm_rmsfe_result mean=rmse2;
RUN;

DATA ecm_rmsfe_final;
    set ecm_rmsfe_result;
    rmsfe_ecm = sqrt(rmse2);
RUN;

PROC PRINT data=ecm_rmsfe_final label noobs;
    var rmsfe_ecm;
    label rmsfe_ecm = "ECM Model RMSFE";
    title "Mean Square Forecast Error (RMSFE) - ECM Model";
RUN;

/* Compare to a naive model (constant inflation) */
PROC MEANS data=estimation noprint;
    where observation_date >= '01JAN1985'd;
    var dif_p;
    output out=naif mean=mean_infl;
RUN;

DATA pred_naif;
    if _n_ = 1 then set naif;
    set prediction;
    predicted_naif = mean_infl;
    erreur_naif = dif_p - predicted_naif;
    erreur_naif2 = erreur_naif**2;
RUN;

PROC MEANS data=pred_naif noprint;
    var erreur_naif2;
    output out=naif_rmsfe_result mean=rmse2_naif;
RUN;

DATA naif_rmsfe_final;
    set naif_rmsfe_result;
    rmsfe_naif = sqrt(rmse2_naif);
RUN;

PROC PRINT data=naif_rmsfe_final label noobs;
    var rmsfe_naif;
    label rmsfe_naif = "RMSFE of the naive model";
    title "Mean Square Forecast Error (RMSFE) - Naive Model";
RUN;


/* Step 7 – Graphic approach */
DATA memoire.USA_ALL_Ps;
    set memoire.USA_ALL_Ps;
    ecart_p = p - p_star; /* écart en log */
RUN;

PROC SGPLOT data=memoire.USA_ALL_Ps;
    series x=observation_date y=ecart_p / lineattrs=(color=red) legendlabel="Écart (p - p*)";
    series x=observation_date y=inflation / y2axis lineattrs=(color=blue pattern=shortdash) legendlabel="Inflation (%)";
    xaxis label="Date";
    yaxis label="Deviation (log)";
    y2axis label="Inflation (%)";
    title "Link between p - p* and inflation";
RUN;


/* Step 8 - Diebold-Mariano test */
DATA dm_test;
    merge ecm_rmsfe(keep=observation_date erreur2)
          pred_naif(keep=observation_date erreur_naif2);
    by observation_date;

    d = erreur2 - erreur_naif2;
RUN;

PROC PRINT data=dm_test (obs=10);
    var observation_date erreur2 erreur_naif2 d;
RUN;

PROC IML;
    use dm_test;
    read all var {d} into d;
    n = nrow(d);
    dbar = mean(d);
    s2 = var(d);
    dm_stat = dbar / sqrt(s2 / n);
    pval = 2 * (1 - probnorm(abs(dm_stat)));

    print dm_stat pval;
QUIT;

