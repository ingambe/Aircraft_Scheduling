% just to check that the generator don't generate bad formated instance

:- first(V, A), V < 1, A < 1.
:- airport_start(V, A), V < 1, A < 1, #max{K : aircraft(K)} = N, A > N, #max{K : flight(K)} = N2, V > N2.
:- airport_end(V, A), V < 1, A < 1, #max{K : aircraft(K)} = N, A > N, #max{K : flight(K)} = N2, V > N2.
