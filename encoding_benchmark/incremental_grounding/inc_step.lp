% this represent the minimum ground time between two flight (the next airport connection if any)
min_ground_time_flight(F1, T) :- flight(F1), airport_end(F1, A), flight(ISNEXT), airport_start(ISNEXT, A), start(ISNEXT, TCHECK), end(F1, TEND), TCHECK > TEND, #min{K : flight(F2), airport_start(F2, A), start(F2, TSTART), TEND < TSTART, K = TSTART - TEND} = T.

% the minimum ground time for a solution
initial(T) :- #max{K : min_ground_time_flight(_, K)} = T.

% we compute the step increase by getting the average of all minimal ground time
% but to prevent overflow, we ensure to have a correct step increase
step_increase_tmp(T) :- #sum{K : min_ground_time_flight(_, K)} = SUM_GROUND, #count{F : flight(F)} = NB_FLIGHTS, T = SUM_GROUND / NB_FLIGHTS.

step_increase(T) :- step_increase_tmp(T), T != #sup.
% if there is an overflow problem, we take one hour as the step increase
step_increase(3600) :- step_increase_tmp(#sup).