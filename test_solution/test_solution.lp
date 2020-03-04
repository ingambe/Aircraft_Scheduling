% they are compatible and they are assigned to the same aircraft
%compatible(V1, V2) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), tat(V1, MIN), T1 + (MIN * 60) <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2, assign(V1, A), assign(V2, A).

:- assign(V, A1), assign(V, A2), A1 > A2.

% every flight needs to have at least one compatible predecessor
%:- assign(V2, A), not first(V2, A), #count{V1 : compatible(V1, V2)} < 1.

% the first flight is automaticly assigned to the corresponding aircraft
:- first(V, A), not assign(V, A).

% every flight should be assigned
:- flight(V), not assign(V, _).

% every flight should be assign to one and only one aircraft
:- flight(V), #count{A : assign(V, A)} > 1.
:- flight(V), #count{A : assign(V, A)} < 1.

:- max_solution_tat_cost(X), cost(tat, C), K = #count{V : violation_tat(V, _, _)}, X < K * C.

#show .