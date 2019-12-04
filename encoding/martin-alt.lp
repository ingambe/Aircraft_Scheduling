% Add minimal tat to end times of flights

end_tat(V,T+60*M) :- flight(V), end(V,T), tat(V,M).

% Order start times of flights and map end times to them

first(V) :- first(V,P).
route(V) :- flight(V), not first(V).

time(s,A,T) :- start(V,T), airport_start(V,A), route(V).
time(e,A,T) :- end_tat(V,T), airport_end(V,A).

time(A,T) :- time(X,A,T).
time(T)   :- time(A,T).

time_sort(@insert(t,T)) :- time(T).

time_index(T,I) :- time_sort(O), (T,I) = @order(O).

time_next(T1,T2) :- time_index(T1,I), time_index(T2,I+1).

time_skip(A,T,T)   :- time(e,A,T), not time(s,A,T).
time_skip(A,T1,T2) :- time_skip(A,T1,T), time_next(T,T2), not time(s,A,T2).

time_keep(A,T,T)   :- time(e,A,T), time(s,A,T).
time_keep(A,T1,T2) :- time_skip(A,T1,T), time_next(T,T2), time(s,A,T2).

airport_time(A,T2) :- time_keep(A,T1,T2).
airport_time(A,T2) :- airport_next(A,T1,T2), time(s,A,T2).

airport_next(A,T1,T2) :- airport_time(A,T1), time_next(T1,T2).
airport_next(A,T1,T2) :- airport_next(A,T1,T), time_next(T,T2), not time(s,A,T).

%*
time(A,T) :- end_tat(V,T), airport_end(V,A).


next(A,T1,T2) :- time(A,T1), time(A,T2), T1 < T2,
                 T <= T1 : time(A,T), T < T2.
*%


%*
time(@insert(A,T)) :- end_tat(V,T), airport_end(V,A).
time(@insert(A,T)) :- start(V,T), airport_start(V,A), route(V).

value(A,T,I) :- time(A), (T,I) = @order(A).
value(T)     :- value(A,T,I).

next(A,T1,T2) :- value(A,T1,I), value(A,T2,I+1).

% Generate routings for the aircrafts

at(P,A,T1) :- end_tat(V,T1), airport_end(V,A), first(V,P).
at(P,A,T1) :- end_tat(V,T1), airport_end(V,A), assign(V,P).
at(P,A,T2) :- at(P,A,T1), next(A,T1,T2),
              not assign(V,P) : start(V,T1), airport_start(V,A).

{assign(V,P) : start(V,T), airport_start(V,A), route(V)} 1 :- at(P,A,T).

:- route(V), #count{P : assign(V,P)} != 1.

:- first(V,P), value(T), #count{A : at(P,A,T)} > 1.

% Output assignment of flights to aircrafts

#show assign/2.
#show assign(V,P) : first(V,P).
*%
% Term sorting by means of script

#script(lua)

-- table of groups of values
tab = { }

-- insert values of a group denoted by 'groupterm' into table 'tab'
function insert(groupterm, value)
    group = tostring(groupterm)
    if tab[group] == nil then
        tab[group] = { }
    end
    table.insert(tab[group], value)
    return groupterm
end

-- get value-index tuples for values in a group denoted by 'groupterm'
function order(groupterm)
    group = tostring(groupterm)
    table.sort(tab[group])
    result = { }
    for index = 1, #tab[group] do
        if tab[group][index] ~= tab[group][index+1] then
            result[#result+1] = clingo.Tuple({tab[group][index], #result+1})
        end
    end
    return result
end

#end.
