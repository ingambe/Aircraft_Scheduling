#const stepinc = 60.

% GENERATOR

#program base.

compatible2(V1, V2, T2 - T1) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), start(V1, T3), airport_end(V1, A1), airport_start(V2, A1), T1 < T2.

:- flight(V), not routed(V, 1).


#show assign/2.

assign(V, A) :- first(V, A).
assign(V, A) :- assigned(V, A, 1).

%
#program step(t).

#external routed(V, t+1) : flight(V).
#external assigned(V, A, t+1) : flight(V), aircraft(A), not first(V, _).

compatible(V1, V2, t) :- compatible2(V1, V2, T), (t-1) * 3600 <= T, T < t * 3600.

% same aircraft assigned during the whole route
{route(V1, V2, t) : compatible(V1, V2, t)} 1 :- first(V1, _).
{route(V1, V2, t) : compatible(V1, V2, t)} 1 :- flight(V2), not first(V2, _).

assigned(V2, A, t) :- assign(V1, A), route(V1, V2, t).
assigned(V2, A, t) :- assigned(V2, A, t+1).

% route(V1, V2) :- route(V1, V2, t).

routed_now(V1, t) :- route(V1, V2, t), first(V1, _).
routed_now(V2, t) :- route(V1, V2, t), flight(V2), not first(V2, _).

routed(V, t) :- routed_now(V, t).
routed(V, t) :- routed(V, t+1).

:- routed_now(V, t-1), routed(V, t).

% detect each violation
violation_tat(V1, V2, T, t) :- assign(V1, A), assign(V2, A), end(V1, T1), start(V2, T2), start(V1, T3), tat(V1, MIN), T = T1 + MIN - T2, T > 0, T2 > T3.

:~ violation_tat(V1, V2, T, t), cost(tat, C). [C, V1, t]

%{maintenance_after_flight(V1, M, t)} :- route(V1, V2, t), airport_maintenance(M, A), airport_end(V1, A), length_maintenance(M, L), end(V1, T1), start(V2, T2), Z = T2 - T1, Z >= L.
%{maintenance_after_flight(V1, M, t)} :- flight(V1), airport_maintenance(M, A), airport_end(V1, A), flight(V1), not route(V1, _, t).
%{maintenance_after_flight(V1, M, t)} :- maintenance_after_flight(V1, M, t + 1).

%covered(F1, M, 0) :- first(F1, A), maintenance(M).
%covered(F2, M, t) :- first(F1, A), assigned(F2, A, t), start_maintenance_counter(M, A, C), limit_counter(M, L), end(F1, S1), LEFT = L - C, end(F2, S2), B = S2 - S1, B <= LEFT, S1 < S2.
%covered(F2, M, t) :- assigned(F2, A, t), assigned(F1, A, t), end(F1, T1), end(F2, T2), T1 <= T2, maintenance_after_flight(F1, M, t), TIME = T2 - T1, limit_counter(M, L), TIME <= L.

%:- flight(F), maintenance(M), not covered(F, M, t).

%:~ maintenance_after_flight(F, _, t). [101, F]

%#show maintenance_after_flight/3.