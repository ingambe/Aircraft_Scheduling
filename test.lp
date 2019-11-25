aircraft(1..2).
airport(1..3).
flight(1..7).
first(1, 1). first(5, 2). 
airport_start(1, 2). airport_start(2, 3). airport_start(3, 1). airport_start(4, 2). airport_start(5, 3). airport_start(6, 2). airport_start(7, 3). 
airport_end(1, 3). airport_end(2, 1). airport_end(3, 2). airport_end(4, 1). airport_end(5, 2). airport_end(6, 3). airport_end(7, 2). 
start(1, 1574696739). start(2, 1574705864). start(3, 1574714934). start(4, 1574724124). start(5, 1574696136). start(6, 1574707586). start(7, 1574717865). 
end(1, 1574700819). end(2, 1574708984). end(3, 1574719794). end(4, 1574726884). end(5, 1574700876). end(6, 1574711666). end(7, 1574722605). 
tat(1, 42). tat(2, 51). tat(3, 35). tat(4, 39). tat(5, 51). tat(6, 42). tat(7, 51). 

%* One possible solution: 
For aircraft 1
assign(1, 1). assign(2, 1). assign(3, 1). assign(4, 1). 

For aircraft 2
assign(5, 2). assign(6, 2). assign(7, 2). 

*%
