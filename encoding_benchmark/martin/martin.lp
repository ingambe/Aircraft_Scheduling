% Add minimal tat to end times of flights

end_tat(V,T+60*M) :- flight(V), end(V,T), tat(V,M).

% Order times of interest per airport

first(V) :- first(V,P).
route(V) :- flight(V), not first(V).

time(A,T) :- end_tat(V,T), airport_end(V,A).
time(A,T) :- start(V,T), airport_start(V,A), route(V).

next(A,T1,T2) :- time(A,T1), time(A,T2), T1 < T2,
                 T <= T1 : time(A,T), T < T2.

% Generate routings for the aircrafts

at(P,A,T1) :- end_tat(V,T1), airport_end(V,A), first(V,P).
at(P,A,T1) :- end_tat(V,T1), airport_end(V,A), assign(V,P).
at(P,A,T2) :- at(P,A,T1), next(A,T1,T2),
              not assign(V,P) : start(V,T1), airport_start(V,A).

{assign(V,P) : start(V,T), airport_start(V,A), route(V)} 1 :- at(P,A,T).

:- route(V), #count{P : assign(V,P)} != 1.

% Output assignment of flights to aircrafts

#show assign/2.
#show assign(V,P) : first(V,P).
