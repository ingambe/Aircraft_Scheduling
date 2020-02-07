% Constants for configuring the encoding

#const factor = 60. % factor to multiply minimal tat with

#const gap = 8000.  % time of staying at an airport must be shorter than the gap

#const check = 0.   % change to use encoding variant for checking gap of staying

#const choice = 0.  % change to use encoding variant about assignment generation

#const stay = 0.    % change to use encoding variant about staying at an airport

#const keep = 0.    % change to use encoding variant about keeping aircraft locs

#const symm = 0.    % change to disable symmetry breaking of aircraft assignment

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

start_aux(A,T1,T2) :- start_time(A,T1), time_next(T1,T2), not start_last(A,T1).
start_aux(A,T1,T2) :- start_aux(A,T1,T), time_next(T,T2), not time(s,A,T).

start_next(A,T1,T2) :- start_aux(A,T1,T2), time(s,A,T2).

start_time(T) :- start_time(A,T).

start_aux(T1,T2) :- start_time(T1), time_next(T1,T2), not start_last(T1).
start_aux(T1,T2) :- start_aux(T1,T), time_next(T,T2), not start_time(T).

start_next(T1,T2) :- start_aux(T1,T2), start_time(T2).

% Generate routings for the aircrafts

{assign(V,P) : start(V,A,T)} :- at(P,A,T), choice = 0.

:- choice = 0, route(V), #count{P : assign(V,P)} != 1.

{assign(V,P) : first(F,P)} = 1 :- route(V), choice != 0.

:- choice != 0, start(V,A,T), assign(V,P), not at(P,A,T).

:- first(F,P), start_time(A,T), #count{V : start(V,A,T), assign(V,P)} > 1.

K {at(P,A,T)} :- end(V,A,T), first(V,P), keeping(K).
K {at(P,A,T)} :- end(V,A,T), assign(V,P), keeping(K).

at(P,A,T2) :- at(P,A,T1), start_next(A,T1,T2), stay = 0,
              not assign(V,P) : start(V,A,T1).
at(P,A,T2) :- at(P,A,T1), start_next(T1,T2), not start_last(A,T1), stay != 0,
              not assign(V,P) : start(V,A,T1).

:- keeping(0), start_last(A,T), at(P,A,T), not assign(V,P) : start(V,A,T).

:- first(V,P), start_time(T), #count{A : at(P,A,T)} > 1.

% Maximum time of staying at an airport

cutoff(gap)         :- gap != #sup.
cutoff(V,A,T2,G)    :- end_tat(V,A,T1), end(V,A,T2), start_last(A,T), cutoff(K),
                       G = K+T1-T2, G <= T-T2.
cutoff(A,T1,G,T2,K) :- cutoff(V,A,T1,G), start_next(A,T1,T2), 0 < G,
                       K = G+T1-T2.
cutoff(A,T1,G,T2,K) :- cutoff(A,T1,G,T,L), start_next(A,T,T2), 0 < L,
                       K = L+T-T2.

scheme(A,T1,G,0)         :- cutoff(V,A,T1,G), G <= 0.
scheme(A,T1,G,G-K)       :- cutoff(A,T1,G,T2,K), K <= 0, check = 0.
scheme(A,T1,G,G+T4-T2-K) :- cutoff(A,T1,G,T2,K), K <= 0, check != 0,
                            start_next(A,T3,T2), start_next(T3,T4).

budget(V,A,T1,K) :- cutoff(V,A,T1,G), scheme(A,T1,G,K).

remain(P,A,T1,K)       :- budget(V,A,T1,K), first(V,P), check = 0.
remain(P,A,T1,K)       :- budget(V,A,T1,K), assign(V,P), check = 0.
remain(P,A,T2,K+T1-T2) :- remain(P,A,T1,K), start_next(A,T1,T2), 0 < K,
                          not assign(V,P) : start(V,A,T1).
remain(P,A,T2,0)       :- remain(P,A,T1,0), start_next(A,T1,T2).

:- remain(P,A,T,0), start(V,A,T), assign(V,P).

remain(P,T1,K)       :- budget(V,A,T1,K), first(V,P), check != 0.
remain(P,T1,K)       :- budget(V,A,T1,K), assign(V,P), check != 0.
remain(P,T2,K+T1-T2) :- remain(P,T1,K), start_next(T1,T2), 0 < K,
                        not assign(V,P) : start(V,T1).
remain(P,T2,0)       :- remain(P,T1,0), start_next(T1,T2).

:- remain(P,T,0), start(V,T), assign(V,P).

% Symmetry breaking to disambiguate flights

depart_sort(@insert((d,A,T),V)) :- start(V,A,T), symm = 0.

depart_index(A,T,V,I) :- depart_sort((d,A,T)), (V,I) = @order((d,A,T)).
depart_index(A,T,I)   :- depart_index(A,T,V,I).
depart_index(A,T)     :- depart_index(A,T,I).

depart_count(A,T,C) :- depart_index(A,T), C = #max{I : depart_index(A,T,I)}.

passon(A,T,P,1) :- first(V,P), first(V1,P+1), not at(P,A,T),
                   depart_count(A,T,C), first(F,C+1).
passon(A,T,P,I+1) :- passon(A,T,P,I), not depart_count(A,T,I).
                 % depart_count(A,T,C), first(F,P+C-I). % when needed

enable(A,T,1,1)  :- first(V,1),
                    depart_count(A,T,C), first(F,C).
enable(A,T,P2,I) :- first(V,P2), P1 = P2-1,
                    enable(A,T,P1,I), not at(P1,A,T),
                    depart_count(A,T,C), first(F,P2+C-I).
enable(A,T,P2,I) :- first(V,P2), P1 = P2-1,
                    depart_index(A,T,I), I <= P2,
                    depart_index(A,T,V1,I-1), assign(V1,P1),
                    depart_count(A,T,C), first(F,P2+C-I).

:- depart_index(A,T,V,I), assign(V,P), not enable(A,T,P,I).

%*
enable(2,A,T,V1)  :- depart_index(A,T,V1,1), first(V,2), not at(1,A,T).
enable(P2,A,T,V1) :- enable(P1,A,T,V1), first(V,P2), P2 = P1+1, not at(P1,A,T).
enable(P2,A,T,V2) :- depart_next(A,T,V1,V2), first(V,P2), P2 = P1+1, assign(V1,P1).
*%

%*
arrive(V,A,T2,K)    :- budget(V,A,T2,K), 0 < K, symm = 0.
arrive(V,A,T2,#sup) :- end_tat(V,A,T1), end(V,A,T2), start_last(A,T), cutoff(K),
                       arrive(A,T2), T < T1+K.
arrive(A,T2,K)      :- arrive(V,A,T2,K).
arrive(A,T2)        :- arrive(A,T2,K).

arrive_sort(@insert((a,A,T2),K)) :- arrive(A,T2,K).

arrive_index(A,T2,K,I) :- arrive_sort((a,A,T2)), (K,I) = @order((a,A,T2)).

arrive_next(A,T2,K1,K2) :- arrive_index(A,T2,K1,I), arrive_index(A,T2,K2,I+1).
*%


%*
longer(P1,P2,A,T1) :- at(P1,A,T1), first(V,P2), not at(P2,A,T1),
                      not scheme(A,T1,).
longer(P1,P2,A,T2) :- longer(P1,P2,A,T1), start_next(A,T1,T2),
                      not assign(V,P1) : start(V,A,T1).
*%

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
