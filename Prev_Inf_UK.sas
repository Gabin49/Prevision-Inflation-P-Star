libname memoire "/home/u64001580/Économétrie appliquée/MemoireS2";

/* We import data for the US  */
PROC IMPORT datafile = "/home/u64001580/Économétrie appliquée/MemoireS2/UK_M2_1983_2016.csv"
   	dbms = csv 
    out = memoire.UK_M2;
    getnames = yes;
RUN;

PROC IMPORT datafile = "/home/u64001580/Économétrie appliquée/MemoireS2/UK_GDP_1980_2024.csv"
	dbms = csv 
    out = memoire.UK_GDP;
    getnames = yes;
RUN;

PROC IMPORT datafile = "/home/u64001580/Économétrie appliquée/MemoireS2/UK_RGDP_1980_2024.csv"
	dbms = csv 
    out = memoire.UK_RGDP;
    getnames = yes;
RUN;

/* We can merge the tables into one */
DATA memoire.UK_ALL;
    merge memoire.UK_M2
          memoire.UK_GDP
          memoire.UK_RGDP;
    by observation_date;
    where observation_date >= '01JAN1983'd and observation_date < '01JAN2016'd;
RUN;

/* We can plot these data */
PROC SGPLOT data=memoire.UK_ALL;
    series x=observation_date y=MSM2UKQ;
    xaxis label="Date";
    yaxis label="Millions of British Pounds";
    title "M2 for UK";
RUN;

DATA memoire.UK_ALL;
    set memoire.UK_ALL;
	M2V = UKNGDP/MSM2UKQ;
RUN;
PROC SGPLOT data=memoire.UK_ALL;
    series x=observation_date y=M2V;
    xaxis label="Date";
    yaxis label="Ratio";
    title "Velocity of M2 Money Stock";
RUN;

PROC SGPLOT data=memoire.UK_ALL;
    series x=observation_date y=NGDPRSAXDCGBQ;
    xaxis label="Date";
    yaxis label="Millions of Domestic Currency";
    title "Real Gross Domestic Product for UK";
RUN;


/* P and P* plot */
DATA memoire.UK_ALL;
    set memoire.UK_ALL;
    GDPDEF = UKNGDP/NGDPRSAXDCGBQ;
	P = GDPDEF;
	M = MSM2UKQ;
	V = M2V;
	Q = NGDPRSAXDCGBQ;
RUN;

PROC EXPAND data=memoire.UK_ALL out=memoire.UK_ALL_Ps;
    id observation_date;
    convert Q = Q_star / transformout=(movave 4);
RUN;

PROC MEANS data=memoire.UK_ALL_Ps noprint;
    var V;
    output out=UK_mean_V mean=V_star;
RUN;

DATA memoire.UK_ALL_Ps;
    if _n_ = 1 then set UK_mean_V;
    set memoire.UK_ALL_Ps;

    P_star = (M*V_star)/Q_star;
RUN;

PROC SGPLOT data=memoire.UK_ALL_Ps;
    series x=observation_date y=P / lineattrs=(color=blue) 
        legendlabel="Current price level (P)";

    series x=observation_date y=P_star / 
        lineattrs=(color=red pattern=shortdash) 
        legendlabel="Long-run equilibrium price level (P*)";

    xaxis label="Date";
    yaxis label="Price level";
    title "Evolution of p observed and p*";
RUN;

/* Inflation plot */
DATA memoire.UK_ALL_Ps;
    set memoire.UK_ALL_Ps;
    lag4_P = lag4(P);
	inflation = 100 * (P - lag4_P) / lag4_P;
RUN;

PROC SGPLOT data=memoire.UK_ALL_Ps;
    series x=observation_date y=inflation / lineattrs=(color=green);     
    xaxis label="Date";
    yaxis label="(Percent)";
    title "Inflation evolution";
RUN;

/* Step 1 - Preparation of the data */
DATA memoire.UK_ALL_Ps;
    set memoire.UK_ALL_Ps;
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
    ;
RUN;


/* Step 2 – Test the integration of the series */
PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=p_star stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=dif_ps stationarity=(adf=5);
RUN;

PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=p stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=dif_p stationarity=(adf=5);
RUN;

PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=m stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=dif_m stationarity=(adf=5);
RUN;

PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=q stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=dif_q stationarity=(adf=5);
RUN;

PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=v stationarity=(adf=5);
RUN;
PROC ARIMA data=memoire.UK_ALL_Ps;
    identify var=dif_v stationarity=(adf=5);
RUN;


/* Step 3 – Co-integration test */
PROC AUTOREG data=memoire.UK_ALL_Ps;
    model p = p_star / stationarity=(adf=5);
    output out=resultats residual=residus;
RUN;

PROC ARIMA data=resultats;
    identify var=residus stationarity=(adf=5);
RUN;


/* Step 4 – Estimate the error-corrected model (ECM) */
DATA memoire.UK_ECM;
    set memoire.UK_ALL_Ps;
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

PROC MODEL data=memoire.UK_ECM;
    dif_p = gamma*lag_ECM
          + delta1*lag_dif_p + delta2*lag2_dif_p + delta3*lag3_dif_p
          + theta1*lag_dif_m + theta2*lag2_dif_m + theta3*lag3_dif_m
          + phi1*lag_dif_q + phi2*lag2_dif_q + phi3*lag3_dif_q
          + psi1*lag_dif_v + psi2*lag2_dif_v + psi3*lag3_dif_v;
    
    id observation_date;
    fit dif_p / out=memoire.pred_ecm outest=memoire.estimations;
RUN;