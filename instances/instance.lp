maintenance(seven_day).
length_maintenance(seven_day, 14400).
airport_maintenance(seven_day, 4).
airport_maintenance(seven_day, 4).
airport_maintenance(seven_day, 3).
airport_maintenance(seven_day, 1).
airport_maintenance(seven_day, 2).
start_maintenance_counter(seven_day, 1, 201927).
start_maintenance_counter(seven_day, 2, 254244).
limit_counter(seven_day, 604800).
aircraft(1..2).
airport(1..4).
flight(1..7).
first(1, 1). first(5, 2). 
airport_start(1, 2). airport_start(2, 4). airport_start(3, 2). airport_start(4, 4). airport_start(5, 2). airport_start(6, 4). airport_start(7, 3). 
airport_end(1, 4). airport_end(2, 2). airport_end(3, 4). airport_end(4, 2). airport_end(5, 4). airport_end(6, 3). airport_end(7, 2). 
start(1, 1591366701). start(2, 1591385901). start(3, 1591401861). start(4, 1591421961). start(5, 1591371457). start(6, 1591391617). start(7, 1591409497). 
end(1, 1591379361). end(2, 1591392321). end(3, 1591414521). end(4, 1591428381). end(5, 1591381597). end(6, 1591404517). end(7, 1591422517). 
tat(1, 2040). tat(2, 3300). tat(3, 2040). tat(4, 3300). tat(5, 2520). tat(6, 2640). tat(7, 3000). 

%* One possible solution: 
For aircraft 1
assign(1, 1). assign(2, 1). assign(3, 1). assign(4, 1). 

For aircraft 2
assign(5, 2). assign(6, 2). assign(7, 2). 

*%
