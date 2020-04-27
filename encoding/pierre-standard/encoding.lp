%%%%%%%%%%%%%%%%%%%%%%%%%%% FLIGHT ALLOCATION %%%%%%%%%%%%%%%%%%%%%%%%%%%

compatible(F1, F2, T2 - T1 - TAT) :- end(F1, T1), start(F2, T2), airport_end(F1, A1), airport_start(F2, A1), T1 < T2, not first(F2, _), tat(F1, TAT).

{route(F1, F2) : compatible(F1, F2, T)} 1 :- flight(F1).
{route(F1, F2) : compatible(F1, F2, T)} 1 :- flight(F2).

assign(F, A) :- first(F, A).
assign(F2, A) :- assign(F1, A), aircraft(A), route(F1, F2), not first(F2, A).

#show assign/2.
#show maintenance_after_flight/2.

:- flight(F), #count{A : assign(F, A)} != 1.

%%%%%%%%%%%%%%%%%%%%%%%%%%% MAINTENANCE %%%%%%%%%%%%%%%%%%%%%%%%%%%

maintenance_compatible_flight(F, M) :- airport_maintenance(M, A), airport_end(F, A).
maintenance_compatible_route(F1, F2, M) :- maintenance_compatible_flight(F1, M), compatible(F1, F2, T), length_maintenance(M, LM), T >= LM.

{maintenance_after_flight(F1, M)} :- maintenance_compatible_route(F1, F2, M).

maintenance_coverage(F1, M) :- first(F1, A), maintenance(M).
maintenance_coverage(F2, M) :- first(F1, A), assign(F2, A), start_maintenance_counter(M, A, C), limit_counter(M, L), end(F1, S1), LEFT = L - C, end(F2, S2), B = S2 - S1, B <= LEFT, S1 < S2.
maintenance_coverage(F2, M) :- assign(F1, A), assign(F2, A), end(F1, T1), end(F2, T2), T1 < T2, maintenance_after_flight(F1, M), TIME = T2 - T1, limit_counter(M, L), TIME <= L.

:- flight(F), maintenance(M), not maintenance_coverage(F, M).

%%%%%%%%%%%%%%%%%%%%%%%%%%% OPTIMISATION %%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% TAT
violation_tat(F1, F2, T) :- route(F1, F2), compatible(F1, F2, T), T < 0.

%:~ violation_tat(F1, F2, T), cost(tat, C). [C, F1]

computed_cost(tat, T * C) :- #count{F: violation_tat(F, _, _)} = T, cost(tat, C).

:~ computed_cost(tat, C). [C@2]

%%% MAINTENANCE

computed_cost(maintenance, T * 101) :- #count{F: maintenance_after_flight(F, _)} = T.

:~ computed_cost(maintenance, C). [C@1]
