% Constants for configuring the encoding

#const factor = 30. % factor to multiply minimal tat with

#const choice = 0.  % change to use encoding variant about assignment generation

#const stay = 0.    % change to use encoding variant about staying at an airport

#const keep = 0.    % change to use encoding variant about keeping aircraft locs

keeping(0) :- keep = 0.
keeping(1) :- keep != 0.

% Add minimal tat to end times of flights

end_tat(V,A,T+factor*M) :- flight(V), airport_end(V,A), end(V,T), tat(V,M).

% Order (start) times of flights and map end times to (later) start times

first(V) :- flight(V), first(V,P).
route(V) :- flight(V), not first(V).

start(V,A,T) :- route(V), airport_start(V,A), start(V,T).

time(s,A,T) :- start(V,A,T).
time(e,A,T) :- end_tat(V,A,T).

time_sort(@insert(t,T)) :- time(X,A,T).

time_index(T,I) :- time_sort(O), (T,I) = @order(O).

time_next(T1,T2) :- time_index(T1,I), time_index(T2,I+1).

end_aux(A,T,T)   :- time(e,A,T).
end_aux(A,T1,T2) :- end_aux(A,T1,T), time_next(T,T2), not time(s,A,T).

end_next(A,T1,T2) :- end_aux(A,T1,T2), time(s,A,T2).
end_next(A)       :- end_next(A,T1,T2).
end_next          :- end_next(A).

end(V,A,T2) :- end_tat(V,A,T1), end_next(A,T1,T2).

start_last(A,L) :- end_next(A), L = #max{T : time(s,A,T)}.
start_last(L)   :- end_next, L = #max{T : start_last(A,T)}.

start_time(A,T2) :- end_next(A,T1,T2).
start_time(A,T2) :- start_next(A,T1,T2).

start_next(A,T1,T2) :- start_aux(A,T1,T2), time(s,A,T2).

start_aux(A,T1,T2) :- start_time(A,T1), time_next(T1,T2), not start_last(A,T1).
start_aux(A,T1,T2) :- start_aux(A,T1,T), time_next(T,T2), not time(s,A,T).

start_time(T) :- start_time(A,T).

start_aux(T1,T2) :- start_time(T1), time_next(T1,T2), not start_last(T1).
start_aux(T1,T2) :- start_aux(T1,T), time_next(T,T2), not start_time(T).

start_next(T1,T2) :- start_aux(T1,T2), start_time(T2).

% Generate routings for the aircrafts

{assign(V,P) : start(V,A,T)} :- at(P,A,T), choice = 0.

:- choice = 0, route(V), #count{P : assign(V,P)} != 1.

:- choice = 0, first(F,P), start_time(A,T), #count{V : start(V,A,T), assign(V,P)} > 1.

{assign(V,P) : first(F,P)} = 1 :- route(V), choice != 0.

:- choice != 0, start(V,A,T), assign(V,P), not at(P,A,T).

K {at(P,A,T)} :- end(V,A,T), first(V,P), keeping(K).
K {at(P,A,T)} :- end(V,A,T), assign(V,P), keeping(K).

at(P,A,T2) :- at(P,A,T1), start_next(A,T1,T2), stay = 0,
              not assign(V,P) : start(V,A,T1).
at(P,A,T2) :- at(P,A,T1), start_next(T1,T2), not start_last(A,T1), stay != 0,
              not assign(V,P) : start(V,A,T1).

:- keeping(0), start_last(A,T), at(P,A,T), not assign(V,P) : start(V,A,T).

:- first(V,P), start_time(T), #count{A : at(P,A,T)} > 1.

% Output assignment of flights to aircrafts

#show assign/2.
#show assign(V,P) : flight(V), first(V,P).

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
