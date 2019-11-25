aircraft(1..2).
airport(1..3).
flight(1..5).
first(1, 1). first(3, 2). 
airport_start(1, 2). airport_start(2, 3). airport_start(3, 1). airport_start(4, 3). airport_start(5, 1). 
airport_end(1, 3). airport_end(2, 2). airport_end(3, 3). airport_end(4, 1). airport_end(5, 2). 
start(1, 1574692875). start(2, 1574704720). start(3, 1574701378). start(4, 1574711448). start(5, 1574719352). 
end(1, 1574698755). end(2, 1574710600). end(3, 1574705038). end(4, 1574715888). end(5, 1574724152). 
tat(1, 58). tat(2, 44). tat(3, 49). tat(4, 37). tat(5, 46). 

%* One possible solution: 
For aircraft 1
assign(1, 1). assign(2, 1). 

For aircraft 2
assign(3, 2). assign(4, 2). assign(5, 2). 

*%
