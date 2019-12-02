% they are compatible and they are assigned to the same aircraft
compatible(V1, V2) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), tat(V1, MIN), T1 + (MIN * 30) <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2, assign(V1, A), assign(V2, A).

:- assign(V, A1), assign(V, A2), A1 != A2.

% not possible to have aircraft assigned to the same aircraft wich are not compatible
:- assign(V1, A), assign(V2, A), V1 != V2, not compatible(V1, V2) .

% every flight should be assign to one and only one aircraft
:- flight(V), #count(A : assign(V, A)) != 1.