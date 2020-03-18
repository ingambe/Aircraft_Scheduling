#const stepinc = 60.

% GENERATOR

#program base.

{maintenance_after_flight(F, M)} :- flight(F), airport_maintenance(M, A), airport_end(F, A), length_maintenance(M, L), assign(F2, A), assign(F, A), end(F, T), start(F2, T2), LTIME = T2 - T, L <= LTIME.
%{maintenance_after_flight(F, M)} :- flight(F), airport_maintenance(M, A), airport_end(F, A), not route(F, _).

covered(F2, M) :- first(F1, A), assign(F2, A), start_maintenance_counter(M, A, C), limit_counter(M, L), end(F1, S1), LEFT = L - C, end(F2, S2), B = S2 - S1, B <= LEFT.
covered(F2, M) :- assign(F2, A), assign(F1, A), end(F1, T1), end(F2, T2), T1 < T2, maintenance_after_flight(F1, M), TIME = T2 - T1, limit_counter(M, L), TIME <= L.

:- flight(F), maintenance(M), not covered(F, M).

:~ maintenance_after_flight(F, _). [101, F]

% we retrive the initial allocation
% assign(V, A) :- first(V, A).

% and for the other one we assign only one aircraft
% {assign(V,A) : aircraft(A)} = 1 :- flight(V).

compatible2(V1, V2, T2 - T1) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), T1 <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2.

:- flight(V), not routed(V, 1).

#show assign/2.
% #show.
% #show assign(V, A) : first(V, A).
assign(V, A) :- first(V, A).
assign(V, A) :- assigned(V, A, 1).

%
#program step(t).

#external routed(V, t+1) : flight(V).
#external assigned(V, A, t+1) : flight(V), aircraft(A), not first(V, _).

% compatible(V1, V2) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), tat(V1, MIN), T1 + (MIN * 30) <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2, T2 - (T1 + (MIN * 30)) < t.
compatible(V1, V2, t) :- compatible2(V1, V2, T), (t-1) * 3600 <= T, T < t * 3600.

% #program check(t).
% same aircraft assigned during the whole route
% {route(V1, V2) : compatible(V1, V2)} = 1 :- first(V1, _).
% {route(V1, V2) : compatible(V1, V2)} = 1 :- flight(V2), not first(V2, _).

% same aircraft assigned during the whole route
{route(V1, V2, t) : compatible(V1, V2, t)} 1 :- first(V1, _).
{route(V1, V2, t) : compatible(V1, V2, t)} 1 :- flight(V2), not first(V2, _).

% :- route(V1, V2), assign(V1, A1), assign(V2, A2), A1 != A2.
% :- route(V1, V2, t), assign(V1, A), not assign(V2, A).
% :- route(V1, V2, t), assign(V2, A), not assign(V1, A).
assigned(V2, A, t) :- assign(V1, A), route(V1, V2, t).
assigned(V2, A, t) :- assigned(V2, A, t+1).

% route(V1, V2) :- route(V1, V2, t).

routed_now(V1, t) :- route(V1, V2, t), first(V1, _).
routed_now(V2, t) :- route(V1, V2, t), flight(V2), not first(V2, _).

routed(V, t) :- routed_now(V, t).
routed(V, t) :- routed(V, t+1).

:- routed_now(V, t-1), routed(V, t).

% detect each violation
violation_tat(V1, V2, T, t) :- V1 < V2, route(V1, V2, t), end(V1, T1), start(V2, T2), tat(V1, MIN), T = T1 + MIN - T2, T > 0.

:~ violation_tat(V1, V2, T, t), cost(tat, C). [C, V1, t]

