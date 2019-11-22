aircraft(1..2).
airport(1..3).
flight(1..7).
first(1, 1). first(5, 2). 
airport_start(1, 3). airport_start(2, 1). airport_start(3, 3). airport_start(4, 1). airport_start(5, 3). airport_start(6, 2). airport_start(7, 3). 
airport_end(1, 3). airport_end(2, 1). airport_end(3, 3). airport_end(4, 1). airport_end(5, 3). airport_end(6, 2). airport_end(7, 3). 
start(1, 1574437259). start(2, 1574445824). start(3, 1574455252). start(4, 1574464392). start(5, 1574432731). start(6, 1574442416). start(7, 1574449639). 
end(1, 1574443139). end(2, 1574451884). end(3, 1574461132). end(4, 1574469972). end(5, 1574437651). end(6, 1574446256). end(7, 1574455519). 
tat(1, 50). tat(2, 57). tat(3, 50). tat(4, 41). tat(5, 33). tat(6, 42). tat(7, 50). 

%* One possible solution: 
For aircraft 1
assign(1, 1). assign(2, 1). assign(3, 1). assign(4, 1). 

For aircraft 2
assign(5, 2). assign(6, 2). assign(7, 2). 

*%
