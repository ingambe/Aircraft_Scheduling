#const stepinc = 60.

% GENERATOR

#program base.
% we retrive the initial allocation
assign(V, A) :- first(V, A).

compatible(V1, V2) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), tat(V1, MIN), T1 + (MIN * 30) <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2, T2 - (T1 + (MIN * 30)) < 60.

% and for the other one we assign only one aircraft
{assign(V,A) : aircraft(A)} = 1 :- flight(V).


#program step(t).
compatible(V1, V2) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), tat(V1, MIN), T1 + (MIN * 30) <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2, T2 - (T1 + (MIN * 30)) < t.


#program check(t).
% same aircraft assigned during the whole route

{route(V1, V2) : compatible(V1, V2)} = 1 :- first(V1, _).
{route(V1, V2) : compatible(V1, V2)} = 1 :- flight(V2), not first(V2, _).

:- route(V1, V2), assign(V1, A1), assign(V2, A2), A1 != A2.

#show assign/2.