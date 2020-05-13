maintenance(seven_day).
length_maintenance(seven_day, 14400).
airport_maintenance(seven_day, 2).
airport_maintenance(seven_day, 3).
airport_maintenance(seven_day, 4).
start_maintenance_counter(seven_day, 1, 288542).
start_maintenance_counter(seven_day, 2, 292335).
start_maintenance_counter(seven_day, 3, 244523).
start_maintenance_counter(seven_day, 4, 160034).
start_maintenance_counter(seven_day, 5, 285020).
start_maintenance_counter(seven_day, 6, 317092).
start_maintenance_counter(seven_day, 7, 370868).
start_maintenance_counter(seven_day, 8, 260769).
start_maintenance_counter(seven_day, 9, 295403).
start_maintenance_counter(seven_day, 10, 333621).
limit_counter(seven_day, 604800).
aircraft(1..10).
airport(1..20).
flight(1..20).
first(1, 1). first(3, 2). first(5, 3). first(8, 4). first(12, 5). first(14, 6). first(15, 7). first(16, 8). first(18, 9). first(20, 10). 
airport_start(1, 12). airport_start(2, 14). airport_start(3, 11). airport_start(4, 21). airport_start(5, 15). airport_start(6, 16). airport_start(7, 11). airport_start(8, 10). airport_start(9, 6). airport_start(10, 10). airport_start(11, 15). airport_start(12, 14). airport_start(13, 19). airport_start(14, 12). airport_start(15, 15). airport_start(16, 6). airport_start(17, 14). airport_start(18, 7). airport_start(19, 11). airport_start(20, 7). 
airport_end(1, 14). airport_end(2, 7). airport_end(3, 21). airport_end(4, 14). airport_end(5, 16). airport_end(6, 11). airport_end(7, 10). airport_end(8, 6). airport_end(9, 10). airport_end(10, 15). airport_end(11, 11). airport_end(12, 19). airport_end(13, 3). airport_end(14, 11). airport_end(15, 5). airport_end(16, 14). airport_end(17, 11). airport_end(18, 11). airport_end(19, 10). airport_end(20, 3). 
start(1, 1588191178). start(2, 1588217158). start(3, 1588184550). start(4, 1588214790). start(5, 1588180914). start(6, 1588227114). start(7, 1588243074). start(8, 1588210611). start(9, 1588242351). start(10, 1588282611). start(11, 1588320171). start(12, 1588196859). start(13, 1588217799). start(14, 1588206945). start(15, 1588204334). start(16, 1588187865). start(17, 1588229985). start(18, 1588199745). start(19, 1588220265). start(20, 1588192507). 
end(1, 1588201078). end(2, 1588227538). end(3, 1588208250). end(4, 1588232250). end(5, 1588208694). end(6, 1588237614). end(7, 1588250334). end(8, 1588228551). end(9, 1588267791). end(10, 1588295031). end(11, 1588333311). end(12, 1588209279). end(13, 1588231479). end(14, 1588218405). end(15, 1588213034). end(16, 1588203885). end(17, 1588248465). end(18, 1588208445). end(19, 1588227525). end(20, 1588203907). 
tat(1, 2820). tat(2, 3240). tat(3, 3480). tat(4, 3180). tat(5, 2460). tat(6, 2820). tat(7, 3540). tat(8, 3000). tat(9, 2760). tat(10, 3300). tat(11, 2880). tat(12, 2580). tat(13, 2580). tat(14, 2880). tat(15, 3000). tat(16, 3600). tat(17, 2280). tat(18, 3060). tat(19, 3540). tat(20, 2460). 

%* One possible solution: 
For aircraft 1
assign(1, 1). assign(17, 1). 

For aircraft 2
assign(3, 2). assign(4, 2). 

For aircraft 3
assign(5, 3). assign(6, 3). assign(7, 3). 

For aircraft 4
assign(8, 4). assign(9, 4). assign(10, 4). assign(11, 4). 

For aircraft 5
assign(12, 5). assign(13, 5). 

For aircraft 6
assign(14, 6). 

For aircraft 7
assign(15, 7). 

For aircraft 8
assign(2, 8). assign(16, 8). 

For aircraft 9
assign(18, 9). assign(19, 9). 

For aircraft 10
assign(20, 10). 

*%
