cost(tat, 500).
cost(sb, 5000).

aircraft(1..2).
airport(1..3).
flight(1..7).
first(1, 1). first(4, 2). 
airport_start(1, 1). airport_start(2, 2). airport_start(3, 1). airport_start(4, 2). airport_start(5, 1). airport_start(6, 3). airport_start(7, 1). 
airport_end(1, 2). airport_end(2, 1). airport_end(3, 3). airport_end(4, 1). airport_end(5, 3). airport_end(6, 1). airport_end(7, 2). 
start(1, 1574672760). start(2, 1574683960). start(3, 1574692909). start(4, 1574675239). start(5, 1574680229). start(6, 1574697131). start(7, 1574706592). 
end(1, 1574678400). end(2, 1574688100). end(3, 1574697949). end(4, 1574680219). end(5, 1574690625). end(6, 1574702531). end(7, 1574712232). 
tat(1, 2580). tat(2, 2040). tat(3, 2460). tat(4, 2940). tat(5, 3060). tat(6, 1920). tat(7, 2580).

%* One possible solution: 
For aircraft 1
assign(1, 1). assign(2, 1). assign(3, 1). 

For aircraft 2
assign(4, 2). assign(5, 2). assign(6, 2). assign(7, 2). 

*%
