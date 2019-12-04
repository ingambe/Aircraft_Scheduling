aircraft(1..2).
airport(1..3).
flight(1..9).
first(1, 1). first(5, 2). 
airport_start(1, 1). airport_start(2, 3). airport_start(3, 2). airport_start(4, 1). airport_start(5, 2). airport_start(6, 1). airport_start(7, 2). airport_start(8, 1). airport_start(9, 2). 
airport_end(1, 3). airport_end(2, 2). airport_end(3, 1). airport_end(4, 2). airport_end(5, 1). airport_end(6, 2). airport_end(7, 1). airport_end(8, 2). airport_end(9, 1). 
start(1, 1575478994). start(2, 1575482973). start(3, 1575487273). start(4, 1575491078). start(5, 1575478329). start(6, 1575482223). start(7, 1575485641). start(8, 1575489427). start(9, 1575492887). 
end(1, 1575482174). end(2, 1575486573). end(3, 1575490453). end(4, 1575494018). end(5, 1575481389). end(6, 1575485163). end(7, 1575488821). end(8, 1575492367). end(9, 1575496067). 
tat(1, 12). tat(2, 10). tat(3, 9). tat(4, 7). tat(5, 12). tat(6, 7). tat(7, 9). tat(8, 7). tat(9, 9). 

%* One possible solution: 
For aircraft 1
assign(1, 1). assign(2, 1). assign(3, 1). assign(4, 1). 

For aircraft 2
assign(5, 2). assign(6, 2). assign(7, 2). assign(8, 2). assign(9, 2). 

*%
