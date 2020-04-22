#const stepinc = 60.

% GENERATOR

#program base.

compatible2(V1, V2, T2 - T1) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), start(V1, T3), airport_end(V1, A1), airport_start(V2, A1), T1 < T2, not first(V2, _).

assign(V, A) :- first(V, A).
assign(V, A) :- assigned(V, A, 0).

:- flight(V), #count{A : assign(V, A)} != 1.

:- flight(V), not first(V, _), not routed(in, V, 0).

:- assign(V1, A) , assign(V2, A), #count{T : compatible2(V1, V2, T)} == 0, V1 != V2.

#external routed(in, V, 0) : flight(V), not first(V, _).
#external assigned(V, A, 0) : flight(V), aircraft(A), not first(V, _).

maintenance_compatible(V, M) :- airport_maintenance(M, A), airport_end(V, A).

{maintenance_after_flight(V, M)} :- maintenance_compatible(V, M).

maintenance_plane(A, M, T) :- assign(V, A), maintenance_after_flight(V, M), end(V, T).

maintenance_coverage(F1, M) :- first(F1, A), maintenance(M).
maintenance_coverage(F2, M) :- first(F1, A), assign(F2, A), start_maintenance_counter(M, A, C), limit_counter(M, L), end(F1, S1), LEFT = L - C, end(F2, S2), B = S2 - S1, B <= LEFT, S1 < S2.
maintenance_coverage(F2, M) :- assign(F1, A), assign(F2, A), end(F1, T1), end(F2, T2), T1 < T2, maintenance_after_flight(F1, M), TIME = T2 - T1, limit_counter(M, L), TIME <= L.

%:- maintenance(M), flight(V), not maintenance_coverage(V, M).

:~ maintenance_after_flight(V, _). [101, V]

#show assign/2.

#program step(t).

compatible(V1, V2, T, t) :- compatible2(V1, V2, T), (t-1) * 3600 <= T, T < t * 3600.

% same aircraft assigned during the whole route
{route(V1, V2, t) : compatible(V1, V2, T, t)} 1 :- flight(V1).
{route(V1, V2, t) : compatible(V1, V2, T, t)} 1 :- flight(V2).

routed_now(in, V2, t)  :- route(V1, V2, t).
routed_now(out, V1, t) :- route(V1, V2, t).

routed(X, V, t-1) :- routed_now(X, V, t).
routed(X, V, t-1) :- routed(X, V, t).

:- routed_now(X, V, t-1), routed(X, V, t-1).

:- route(V1, V2, t), compatible(V1, V2, T, t), T < #sum+{N, M : maintenance_after_flight(V1, M), length_maintenance(M, N)}.

#external routed(in,V,t) : flight(V), not first(V, _).
#external routed(out,V,t) : flight(V).

assign_now(V2, A, t) :- assign(V1, A), route(V1, V2, t).

assigned(V, A, t-1) :- assign_now(V, A, t).
assigned(V, A, t-1) :- assigned(V, A, t).

:- assign_now(V, A, t-1), assigned(V, A, t-1).

#external assigned(V, A, t) : flight(V), aircraft(A), not first(V, _).

violation_tat(V1, V2, T, t) :- route(V1, V2, t), compatible(V1, V2, T, t), tat(V1, MIN), T < MIN.

:~ violation_tat(V1, V2, T, t), cost(tat, C). [C, V1]
