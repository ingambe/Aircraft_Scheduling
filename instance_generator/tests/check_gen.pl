% just to check that the generator don't generate bad formated instance

% start at 1
:- first(V, A), V < 1, A < 1.
% we make sure we don't create tat, airport_start, airport_end for flight who doesn't exist
:- airport_start(V, A), V < 1, A < 1, #max{K : aircraft(K)} = N, A > N, #max{K : flight(K)} = N2, V > N2.
:- airport_end(V, A), V < 1, A < 1, #max{K : aircraft(K)} = N, A > N, #max{K : flight(K)} = N2, V > N2.
:- tat(V, A), V < 1, A < 1, #max{K : aircraft(K)} = N, A > N, #max{K : flight(K)} = N2, V > N2.

% the end of the flight is after the start
:- start(V, T1), end(V, T2), T1 >= T2.

% the start and end airport should be different for each flight
:- airport_start(V, A), airport_end(V, A).

% every flight has a tat, an airport start, an airport end, a start and end date
:- flight(N), #count{K : tat(N, K)} != 1.
:- flight(N), #count{K : airport_start(N, K)} != 1.
:- flight(N), #count{K : airport_end(N, K)} != 1.
:- flight(N), #count{K : start(N, K)} != 1.
:- flight(N), #count{K : end(N, K)} != 1.