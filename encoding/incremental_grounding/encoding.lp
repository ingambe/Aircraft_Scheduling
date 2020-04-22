#const iter_sec_increased = 3600.

% GENERATOR

#program base.

compatible2(V1, V2, T2 - T1 - TAT) :- end(V1, T1), start(V2, T2), airport_end(V1, A1), airport_start(V2, A1), tat(V1, TAT), T1 < T2.

maintenance_compatible(V, M) :- airport_maintenance(M, A), airport_end(V, A).

routed(V, 1) :- first(V, _).

:- flight(V), not routed(V, 1).

#show best/1.
:~ total_cost(C, t). [C]

#show assign/2.

assign(V, A) :- first(V, A).
assign(V, A) :- assigned(V, A, 1).

attach(V, A) :- attached(V, A, 1).

violation_tat(V1, V2, T) :- assign(V1, A), assign(V2, A), end(V1, T1), start(V2, T2), tat(V1, MIN), T = T1 + MIN - T2, T > 0, T1 < T2.
total_cost(T1 + T2, t) :- K1 = #count{V : violation_tat(V, _, _)}, cost(tat, C1), T1 = K1 * C1, K2 = #count{V : attach(V, _)}, T2 = K2 * 101.
#show attach/2.

cover(F1, M) :- first(F1, A), maintenance(M).
cover(F1, M) :- covered(F1, M, 1).

:- flight(F), maintenance(M), not cover(F, M).

#program step(t).

#external routed(V, t+1) : flight(V).
#external assigned(V, A, t+1) : flight(V), aircraft(A), not first(V, _).
#external covered(V, M, t+1) : flight(V), maintenance(M), not first(V, _).
#external attached(V, M, t+1) : flight(V), maintenance(M), maintenance_compatible(V, M).

compatible(V1, V2, t) :- compatible2(V1, V2, T), (t-1) * iter_sec_increased <= T, T < t * iter_sec_increased.

% same aircraft assigned during the whole route
{route(V1, V2, t) : compatible(V1, V2, t)} 1 :- flight(V1).

assigned(V2, A, t) :- assign(V1, A), route(V1, V2, t).
assigned(V2, A, t) :- assigned(V2, A, t+1).

{attach_maintenance(V, M, t)} :- routed(V, t), maintenance(M), maintenance_compatible(V, M).

attached(V, M, t) :- attach_maintenance(V, M, t).
attached(V, M, t) :- attached(V, M, t+1).

:- attached(V, M, t), attach_maintenance(V, M, t-1).

covered(F2, M, t) :- first(F1, A), assigned(F2, A, t), start_maintenance_counter(M, A, C), limit_counter(M, L), end(F1, S1), LEFT = L - C, end(F2, S2), B = S2 - S1, B <= LEFT, S1 < S2.
covered(F2, M, t) :- assign(F1, A), assigned(F2, A, t), attached(F1, M, t), end(F1, T1), end(F2, T2), T1 < T2, TIME = T2 - T1, limit_counter(M, L), TIME <= L.
covered(F2, M, t) :- covered(F2, M, t+1).

routed_now(V2, t) :- route(V1, V2, t), flight(V2), not first(V2, _).

routed(V, t) :- routed_now(V, t).
routed(V, t) :- routed(V, t+1).

:- routed_now(V, t-1), routed(V, t).