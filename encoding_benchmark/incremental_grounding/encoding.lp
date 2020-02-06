#const stepinc = 60.

% GENERATOR

#program base.
% we retrive the initial allocation
% assign(V, A) :- first(V, A).

% and for the other one we assign only one aircraft
% {assign(V,A) : aircraft(A)} = 1 :- flight(V).

compatible2(V1, V2, T2 - (T1 + (MIN * 60))) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), tat(V1, MIN), T1 + (MIN * 60) <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 < V2.
%compatible2(V1, V2,  T2 - T1) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), T1 <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 < V2.



:- flight(V), not routed(V, 1).

#show assign/2.
% #show.
% #show assign(V, A) : first(V, A).
assign(V, A) :- first(V, A).
assign(V, A) :- assigned(V, A, 1).

solution_cost(0, 0).

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
%*
% detect each violation
violation_tat(V1, V2, T, t) :- V1 < V2, route(V1, V2, t), end(V1, T1), start(V2, T2), tat(V1, MIN), T = (T1 + MIN * 60) - T2, T > 0.

% handle the violation cost
tat_cost(X, t) :- cost(tat, C), #count{V1 : violation_tat(V1, _, T, t)}= TAT, X = C * TAT.

solution_cost(C, t) :- C = C1 + C2, tat_cost(C1, t), solution_cost(C2, t - 1).

:~ solution_cost(C, t). [C]
*%