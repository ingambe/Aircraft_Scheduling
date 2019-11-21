% DATA

aircraft(1..2).
flight(1..6).
airport(1..2).
% define the first flights of each aircraft
% first(FLIGHT, AIRCRAFT).
first(1, 1). first(2, 1).
% defined the airport of start
airport_start(1, 2). airport_start(2, 1). airport_start(3, 1). airport_start(4, 2). airport_start(5, 2). airport_start(6, 1).
% airport of end of each flight
airport_end(1, 1). airport_end(2, 2). airport_end(3, 2). airport_end(4, 1). airport_end(5, 1). airport_end(6, 2).
% define the time of start of a flight, the date is EPOCH time represented by a timestamp
start(1, 845920800). start(2, 845917800). start(3, 845928000). start(4, 845929800). start(5, 845935200). start(6, 845937000). 
% define the time of the end of a flight
end(1, 845924400). end(2, 845926200). end(3, 845933400). end(4, 845931600). end(5, 845938800). end(6, 845940600). 
% define the tat minimal at the end of the flight (in minutes)
tat(1..6, 30).

% GENERATOR

% two flights are compatible if they can follow each other
compatible(V1, V2) :- flight(V1), flight(V2), end(V1, T1), start(V2, T2), tat(V1, MIN), T1 + (MIN * 60) <= T2, airport_end(V1, A1), airport_start(V2, A1), V1 != V2.

% we retrive the initial allocation
assign(V, A) :- first(V, A).

% and for the other one we assign only one aircraft
{assign(V,A) : aircraft(A)} = 1 :- flight(V).

{route(V1, V2) : compatible(V1, V2)} = 1 :- first(V1, _).
{route(V1, V2) : compatible(V1, V2)} = 1 :- flight(V2), not first(V2, _).

% same aircraft assigned during the whole route
:- route(V1, V2), assign(V1, A1), assign(V2, A2), A1 != A2.

#show route/2.