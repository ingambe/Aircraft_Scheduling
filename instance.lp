% DATA

aircraft(1..2).

flight(1..6).

airport(1..2).

% define the first flights of each aircraft
% first(FLIGHT, AIRCRAFT).
first(1, 1).
first(2, 2). % changed AIRCRAFT from 1 to 2 here

% defined the airport of start
airport_start(1, 2).
airport_start(2, 1).
airport_start(3, 1).
airport_start(4, 2).
airport_start(5, 2).
airport_start(6, 1).

% airport of end of each flight
airport_end(1, 1).
airport_end(2, 2).
airport_end(3, 2).
airport_end(4, 1).
airport_end(5, 1).
airport_end(6, 2).

% define the time of start of a flight, the date is EPOCH time represented by a timestamp
start(1, 845920800).
start(2, 845917800).
start(3, 845928000).
start(4, 845929800).
start(5, 845935200).
start(6, 845937000).

% define the time of the end of a flight
end(1, 845924400).
end(2, 845926200).
end(3, 845933400).
end(4, 845931600).
end(5, 845938800).
end(6, 845940600).

% define the tat minimal at the end of the flight (in minutes)
tat(1..6, 30).
