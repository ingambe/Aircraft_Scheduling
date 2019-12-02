% GENERATOR

% two flights are compatible if they can follow each other
compatible(V1, V2) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), tat(V1, MIN), T1 + (MIN * 30) <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2, T2 - (T1 + (MIN * 30) ) < 8000.

% we retrive the initial allocation
assign(V, A) :- first(V, A).

% we assign the same aircraft in the route
assign(V2, A) :- assign(V1, A), aircraft(A), route(V1, V2), not first(V2, A).


{route(V1, V2) : compatible(V1, V2)} = 1 :- first(V1, _).
{route(V1, V2) : compatible(V1, V2)} = 1 :- flight(V2), not first(V2, _).

% same aircraft assigned during the whole route
:- route(V1, V2), assign(V1, A), not assign(V2, A).
:- route(V1, V2), assign(V2, A), not assign(V1, A).

#show assign/2.