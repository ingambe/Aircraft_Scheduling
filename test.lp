aircraft(1..2).
airport(1..3).
flight(1..5).
first(1, 1). first(4, 2). 
airport_start(1, 2). airport_start(2, 1). airport_start(3, 3). airport_start(4, 2). airport_start(5, 3). 
airport_end(1, 1). airport_end(2, 3). airport_end(3, 1). airport_end(4, 3). airport_end(5, 1). 
start(1, 1574671929). start(2, 1574681943). start(3, 1574692643). start(4, 1574674469). start(5, 1574684866). 
end(1, 1574676669). end(2, 1574688183). end(3, 1574696663). end(4, 1574679749). end(5, 1574688886). 
tat(1, 48). tat(2, 35). tat(3, 41). tat(4, 41). tat(5, 41). 

%* One possible solution: 
For aircraft 1
assign(1, 1). assign(2, 1). assign(3, 1). 

For aircraft 2
assign(4, 2). assign(5, 2). 

*%
