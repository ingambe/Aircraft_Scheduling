% auxiliary predicates for (preassigned) flights

flight(F, A, S, B, T) :- flight(F),
                         airport_start(F, A), start(F, S),
                         airport_end(F, B), end(F, T).
flight(A, S, B, T)    :- flight(F, A, S, B, T).

fixed(F, A, S, B, T, P) :- flight(F, A, S, B, T), first(F, P).
fixed(B, T)             :- fixed(F, A, S, B, T, P).
fixed(F)                :- fixed(F, A, S, B, T, P).

range(F, A, S, B, T) :- flight(F, A, S, B, T), not fixed(F).
range(A, S, B, T)    :- range(F, A, S, B, T).
range(A, S, T)       :- range(A, S, B, T).
range(S, T)          :- range(A, S, T).
range(S)             :- range(S, T).

% compatible flights w.r.t. maintenances

maintenance(M, L)       :- maintenance(M),
                           limit_counter(M, L).
maintenance(M, L, N)    :- maintenance(M, L),
                           length_maintenance(M, N).
maintenance(M, L, N, B) :- maintenance(M, L, N),
                           airport_maintenance(M, B).

combinable(A, S1, B, T1, S2, T2, G) :- flight(A, S1, B, T1),
                                       range(B, S2, T2),
                                       G = S2 - T1, 0 <= G.
combinable(B, T1, S2, T2, G)        :- combinable(A, S1, B, T1, S2, T2, G).
combinable(B, T1, T2)               :- combinable(B, T1, S2, T2, G),
                                       fixed(B, T1).

maintainable(M, B, T1, S2, T2, S, T) :- maintenance(M, L, N, B),
                                        combinable(B, T1, S2, T2, G), N <= G,
                                        S = T1 + N,
                                        T = T1 + L, T2 <= T.
maintainable(M, B, T1, S, T)         :- maintainable(M, B, T1, S2, T2, S, T).
maintainable(M, T1, S, T)            :- maintainable(M, B, T1, S, T).

initial(M, A, S1, B, T1, T2, T, P) :- fixed(F, A, S1, B, T1, P),
                                      combinable(B, T1, T2),
                                      maintenance(M, L),
                                      start_maintenance_counter(M, P, Q),
                                      T = T1 + L - Q, T2 <= T.
initial(M, A, S1, B, T1, T2)       :- initial(M, A, S1, B, T1, T2, T, P).
initial(M, T1, T, P)               :- initial(M, A, S1, B, T1, T2, T, P).

contain(M, S, T) :- initial(M, S, T, P).
contain(M, S, T) :- maintainable(M, T1, S, T).
contain(S, T)    :- contain(M, S, T).

include(S, T, S1)     :- contain(S, T),
                         range(S1), S <= S1, S1 <= T.
include(S, T, S1, T1) :- include(S, T, S1),
                         range(S1, T1), T1 <= T.

support(M, A, S1, B, T1, S2, T2) :- combinable(A, S1, B, T1, S2, T2, G),
                                    initial(M, A, S1, B, T1, T2).
support(M, A, S1, B, T1, S2, T2) :- combinable(A, S1, B, T1, S2, T2, G),
                                    maintainable(M, B, T1, S2, T2, S, T).
support(M, A, S1, B, T1, S2, T2) :- combinable(A, S1, B, T1, S2, T2, G),
                                    range(A, S1, B, T1),
                                    contain(M, S, T),
                                    include(S, T, S1, T1),
                                    include(S, T, S2, T2).

dismiss(A, S1, B, T1, S2, T2) :- combinable(A, S1, B, T1, S2, T2, G),
                                 maintenance(M),
                                 not support(M, A, S1, B, T1, S2, T2).

utilize(A, S1, B, T1, S2, T2, G) :- combinable(A, S1, B, T1, S2, T2, G),
                                    not dismiss(A, S1, B, T1, S2, T2).

compatible(F1, B, T1, F2, G) :- utilize(A, S1, B, T1, S2, T2, G),
                                flight(F1, A, S1, B, T1),
                                range(F2, B, S2, C, T2).
compatible(B, T1, F2, G)     :- compatible(F1, B, T1, F2, G).
compatible(B, T1, G)         :- compatible(B, T1, F2, G).

% maintenance slots and scopes

guaranteed(M, S1, T1, P) :- initial(M, S, T, P),
                            include(S, T, S1, T1).

guarantone(M, S1, T1) :- guaranteed(M, S1, T1, P).
guarantall(M, S1, T1) :- guarantone(M, S1, T1),
                         guaranteed(M, S1, T1, P) : fixed(F, A, S, B, T, P), T <= S1.

maintaintime(M, T1, S2, T2) :- maintainable(M, T1, S, T),
                               include(S, T, S2, T2),
                               not guarantall(M, S2, T2).
maintaintime(M, T1)         :- maintaintime(M, T1, S2, T2).
maintaintime(M, B, T1)      :- maintainable(M, B, T1, S, T),
                               maintaintime(M, T1).

maintenances(B, T1)    :- maintaintime(M, B, T1).
maintenances(B, T1, O) :- maintenances(B, T1),
                          O = #sum+{N, M : maintaintime(M, B, T1),
                                           maintenance(M, L, N, B)}.

mainduration(B, T1, G) :- compatible(B, T1, G),
                          maintenances(B, T1, O), G < O.

% generate the routing

{route(F1, F2, G) : compatible(F1, B, T1, F2, G)} = 1 :- range(F2, B, S2, C, T2).

:- flight(F1, A, S1, B, T1),
   #count{F2 : route(F1, F2, G)} > 1.

assign(F1, P) :- fixed(F1, A, S1, B, T1, P).
assign(F2, P) :- route(F1, F2, G), assign(F1, P).

:- flight(F, A, S, B, T),
   #count{P : assign(F, P)} != 1.

% generate maintenances

{maintain(M, T, P)} :- maintaintime(M, T),
                       fixed(F1, A, S1, B, T1, P), T1 <= T.

:- maintain(M, T, P),
   not assign(F, P) : flight(F, A, S, B, T),
                      maintaintime(M, B, T).

forbid(T, G, P) :- mainduration(B, T, G),
                   fixed(F1, A1, S1, B1, T1, P), T1 <= T,
                   G < #sum+{N, M : maintain(M, T, P),
                                    maintaintime(M, B, T),
                                    maintenance(M, L, N, B)}.

:- compatible(B, T, F, G),
   mainduration(B, T, G),
   forbid(T, G, P),
   assign(F, P).

covered(M, S, T, P) :- maintain(M, T1, P),
                       maintaintime(M, T1, S, T),
                       not guaranteed(M, S, T, P).

:- range(F, A, S, B, T),
   maintenance(M),
   assign(F, P),
   not guaranteed(M, S, T, P),
   not covered(M, S, T, P).

% minimize maintenances and tat violations

:~ maintain(M, T, P). [101, T, P]

violation_tat(F1, F2) :- route(F1, F2, G), tat(F1, D), G < D.

:~ violation_tat(F1, F2), cost(tat, K). [K, F1]

% output flight assignment and maintenances

#show assign/2.
#show maintain/3.
