% DOMAIN

% auxiliary predicates for airports and times of flights

first(F) :- flight(F), first(F, P).

flight(F, A, S, B, T) :- flight(F),
                         airport_start(F, A), start(F, S),
                         airport_end(F, B), end(F, T).

% auxiliary predicates for compatible flights

compatible(F1, B, T1, F2, S2, T2) :- flight(F1, A, S1, B, T1),
                                     flight(F2, B, S2, C, T2), T1 <= S2,
                                     not first(F2).
compatible(B, T1, F2, S2, T2)     :- compatible(F1, B, T1, F2, S2, T2).

% initially covered intervals for maintenances per plain

includable(F, P, T, T1, M) :- flight(F, A, S, B, T), first(F, P),
                              start_maintenance_counter(M, P, Q),
                              limit_counter(M, L), T1 = T + L - Q.

% intervals with successor flights covered after maintenances

extensible(B, T1, S, T, M) :- compatible(B, T1, F2, S2, T2),
                              airport_maintenance(M, B),
                              length_maintenance(M, N), S = T1 + N, S <= S2,
                              limit_counter(M, L), T = T1 + L, T2 <= T.
extensible(T1, S, T, M)    :- extensible(B, T1, S, T, M).

% successor flights covered by intervals

time_range(S, T)    :- includable(F, P, S, T, M).
time_range(S, T)    :- extensible(T1, S, T, M).
time_range(S, T, F) :- time_range(S, T),
                       flight(F, B, S2, C, T2), S <= S2, T2 <= T,
                       not first(F).

% successor flights (additionally) covered when maintaining a plain at some time

maintainable(P, T2, F2, M) :- includable(F1, P, S1, T1, M),
                              extensible(T2, S, T, M), S1 <= T2,
                              time_range(S, T, F2),
                              not time_range(S1, T1, F2).
maintainable(P, T2, M)     :- maintainable(P, T2, F2, M).
maintainable(P, T2)        :- maintainable(P, T2, M).

% sum the lengths of maintenances that can be performed for a plain at some time

maintenances(P, T2, O) :- maintainable(P, T2),
                          O = #sum+{N, M : maintainable(P, T2, M),
                                           length_maintenance(M, N)}.

% GENERATE

% select some compatible predecessor for each successor flight

{route(F1, F2) : compatible(F1, B, T1, F2, S2, T2)} = 1 :-
                          flight(F2, B, S2, C, T2), not first(F2).

% no flight can have more than one direct successor

:- flight(F1, A, S1, B, T1), #count{F2 : route(F1, F2)} > 1.

% propagate assigned plains from first flights over successors

assign(F1, P) :- flight(F1, A, S1, B, T1), first(F1, P).
assign(F2, P) :- assign(F1, P), route(F1, F2).

% each flight must be assigned to exactly one plain (redundant constraint)

:- flight(F, A, S, B, T), #count{P : assign(F, P)} != 1.

% can maintain after an assigned flight if some successor flight may be covered

{maintain(P, T1, M)} :- flight(F1, A, S1, B, T1), extensible(B, T1, S, T, M),
                        maintainable(P, T1, M), assign(F1, P).

% maintenances for a plain must be finished before successor flight's start time

:- maintenances(P, T1, O), compatible(B, T1, F2, S2, T2), D = S2 - T1, D < O,
   assign(F2, P), D < #sum+{N, M : maintain(P, T1, M),
                                   airport_maintenance(M, B),
                                   length_maintenance(M, N)}.

% flights covered by maintenances for a plain

covered(F1, P, M) :- includable(F1, P, S, T, M), S <= T.
covered(F2, P, M) :- includable(F1, P, S, T, M), time_range(S, T, F2).
covered(F2, P, M) :- maintainable(P, T1, F2, M), maintain(P, T1, M).

% flights assigned to a plain must be covered for each maintenance kind

:- flight(F, A, S, B, T), maintenance(M), assign(F, P), not covered(F, P, M).

% OPTIMIZE

% each time at which maintenance is performed for a plain is penalized by 1

:~ maintain(P, T1, M). [1, P, T1]

% each flight connection shorter than time at terminal is penalized by cost

violation_tat(F1, F2) :- compatible(F1, B, T1, F2, S2, T2), route(F1, F2),
                         tat(F1, D), S2 < T1 + D.

:~ violation_tat(F1, F2), cost(tat, K). [K, F1]

% DISPLAY

% output assigned plains and maintenances for plains

#show assign/2.
#show maintain/3.
