% GENERATOR

% two flights are compatible if they can follow each other
%compatible(V1, V2) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), tat(V1, MIN), T1 + (MIN * 60) <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2.
compatible(V1, V2) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), T1 <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2.

% we retrive the initial allocation
assign(V, A) :- first(V, A).

% we assign the same aircraft in the route
assign(V2, A) :- assign(V1, A), aircraft(A), route(V1, V2), not first(V2, A).


{route(V1, V2) : compatible(V1, V2)} = 1 :- first(V1, _).
{route(V1, V2) : compatible(V1, V2)} = 1 :- flight(V2), not first(V2, _).

% same aircraft assigned during the whole route
:- route(V1, V2), assign(V1, A), not assign(V2, A).
:- route(V1, V2), assign(V2, A), not assign(V1, A).

violation_tat(V1, V2, T) :- V1 < V2, route(V1, V2), end(V1, T1), start(V2, T2), tat(V1, SEC), T = T1 + SEC - T2, T > 0.

:~ violation_tat(V1, V2, T), cost(tat, C). [C, V1]

{maintenance_after_flight(F, M)} :- flight(F), airport_maintenance(M, A), airport_end(F, A), length_maintenance(M, L), route(F, F2), end(F, T), start(F2, T2), LTIME = T2 - T, L <= LTIME.
%{maintenance_after_flight(F, M)} :- flight(F), airport_maintenance(M, A), airport_end(F, A), not route(F, _).

covered(F2, M) :- first(F1, A), assign(F2, A), start_maintenance_counter(M, A, C), limit_counter(M, L), end(F1, S1), LEFT = L - C, end(F2, S2), B = S2 - S1, B <= LEFT.
covered(F2, M) :- assign(F2, A), assign(F1, A), end(F1, T1), end(F2, T2), T1 < T2, maintenance_after_flight(F1, M), TIME = T2 - T1, limit_counter(M, L), TIME <= L.

:- flight(F), maintenance(M), not covered(F, M).

:~ maintenance_after_flight(F, _). [F]

#show assign/2.