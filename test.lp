aircraft(1..2).
airport(1..3).
flight(1..6).
first(1, 1). first(4, 2). 
airport_start(1, 2). airport_start(2, 1). airport_start(3, 2). airport_start(4, 2). airport_start(5, 3). airport_start(6, 1). 
airport_end(1, 1). airport_end(2, 2). airport_end(3, 1). airport_end(4, 3). airport_end(5, 1). airport_end(6, 2). 
start(1, 1574677689). start(2, 1574686287). start(3, 1574693721). start(4, 1574678394). start(5, 1574686874). start(6, 1574695321). 
end(1, 1574684169). end(2, 1574690067). end(3, 1574700201). end(4, 1574683614). end(5, 1574693174). end(6, 1574699101). 
tat(1, 42). tat(2, 48). tat(3, 42). tat(4, 36). tat(5, 59). tat(6, 48). 

%* One possible solution: 
For aircraft 1
assign(1, 1). assign(2, 1). assign(3, 1). 

For aircraft 2
assign(4, 2). assign(5, 2). assign(6, 2). 

*%
