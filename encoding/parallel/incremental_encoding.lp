#const stepinc = 60.

#const weight_maintenance = 101.
#const level_maintenance = 1.

#const weight_tat = 500.
#const level_tat = 2.

#program base.

% auxiliary predicates for flights and maintenances

flight(F, A, S, B, T) :- flight(F),
                         airport_start(F, A), start(F, S),
                         airport_end(F, B), end(F, T).

fixed(F, A, S, B, T, P) :- flight(F, A, S, B, T), first(F, P).

range(F, A, S, B, T) :- flight(F, A, S, B, T), not fixed(F, _, _, _, _, _).
range(S, T)          :- range(F, A, S, B, T).
range(S)             :- range(S, T).

compatible(F1, B, T1, F2, G, G/3600 + 1) :- flight(F1, A, S1, B, T1),
                                            range(F2, B, S2, C, T2),
                                            G = S2 - T1, 0 <= G.
compatible(B, T1, F2, G, I)              :- compatible(F1, B, T1, F2, G, I).
compatible(B, T1, G, I)                  :- compatible(B, T1, F2, G, I).

maintenance(M, L)       :- maintenance(M),
                           limit_counter(M, L).
maintenance(M, L, N)    :- maintenance(M, L),
                           length_maintenance(M, N).
maintenance(M, L, N, B) :- maintenance(M, L, N),
                           airport_maintenance(M, B).

maintainable(M, N, F1, B, T1) :- compatible(F1, B, T1, F2, G, I),
                                 maintenance(M, L, N, B), N <= G.
maintainable(M, N, B, T1)     :- maintainable(M, N, F1, B, T1).
maintainable(M, T1)           :- maintainable(M, N, B, T1).

maintenances(B, T1)    :- maintainable(M, N, B, T1).
maintenances(B, T1, O) :- maintenances(B, T1),
                          O = #sum+{N, M : maintainable(M, N, B, T1)}.

mainduration(B, T1, G, I) :- compatible(B, T1, G, I),
                             maintenances(B, T1, O), G < O.

initial(M, T1, T, P) :- fixed(F, A, S1, B, T1, P),
                        maintenance(M, L),
                        start_maintenance_counter(M, P, Q),
                        T = T1 + L - Q.

contain(M, T1, S, T) :- maintainable(M, T1),
                        maintenance(M, L, N),
                        S = T1 + N,
                        T = T1 + L.
contain(S, T)        :- contain(M, T1, S, T).
contain(S, T)        :- initial(M, S, T, P).

include(S, T, S1)     :- contain(S, T),
                         range(S1), S <= S1, S1 <= T.
include(S, T, S1, T1) :- include(S, T, S1),
                         range(S1, T1), T1 <= T.

guaranteed(M, S1, T1, P) :- initial(M, S, T, P),
                            include(S, T, S1, T1).

maintained(M, T1, S2, T2) :- contain(M, T1, S, T),
                             include(S, T, S2, T2).

% declaration of external route/4 atoms

#external route(F1, F2, G, I) : compatible(F1, B, T1, F2, G, I).

% evaluate the routing

:- range(F2, B, S2, C, T2),
   #count{F1 : route(F1, F2, G, I)} != 1.

:- flight(F1, A, S1, B, T1),
   #count{F2 : route(F1, F2, G, I)} > 1.

assign(F1, P) :- fixed(F1, A, S1, B, T1, P).
assign(F2, P) :- route(F1, F2, G, I), assign(F1, P).

:- flight(F, A, S, B, T),
   #count{P : assign(F, P)} != 1.

% generate maintenances

{maintain(M, T, P)} :- maintainable(M, T),
                       fixed(F1, A, S1, B, T1, P), T1 <= T.

:- maintain(M, T, P),
   not assign(F, P) : maintainable(M, N, F, B, T).

covered(M, S, T, P) :- maintain(M, T1, P),
                       maintained(M, T1, S, T),
                       not guaranteed(M, S, T, P).

:- range(F, A, S, B, T),
   maintenance(M),
   assign(F, P),
   not guaranteed(M, S, T, P),
   not covered(M, S, T, P).

#program step(t).

% incrementally generate the routing

{route(F1, F2, G, t)} :- compatible(F1, B, T1, F2, G, t).

% incrementally check maintenance lengths

forbid(T, G, P) :- mainduration(B, T, G, t),
                   fixed(F1, A1, S1, B1, T1, P), T1 <= T,
                   G < #sum+{N, M : maintainable(M, N, B, T),
                                    maintain(M, T, P)}.

:- compatible(B, T, F, G, t),
   mainduration(B, T, G, t),
   forbid(T, G, P),
   assign(F, P).

% incrementally minimize tat violations

cost(tat, weight_tat, level_tat).
cost(maintenance, weight_maintenance, level_maintenance).

:~ route(F1, F2, G, t), tat(F1, D), G < D, cost(tat, C, L). [C@L, F1, tat]

:~ maintain(M, F, P), cost(maintenance, C, L). [C@L, F, maintenance]

% output flight assignment and maintenances

#show assign/2.
#show maintain/3.

#script (python)

import os
import clingo
import sys
import threading
import time
import copy
import datetime
import pandas as pd

def main(prg):

    # we stop if we have two time in a row the same cost
    # for performance only, can be deactivated
    def handle_stop(m):
        """ This function keep track of the global best solution and the current iteration best solution
        It also handles the timer in order to stop if we don't find a solution after 60 second in the current iteration """
        nonlocal local_best_solution
        nonlocal timer
        nonlocal results
        nonlocal start
        if len(m.cost) > 0:
            seconds = int(time.time() - start)
            result_iteration = [str(seconds), sum(m.cost)]
            results.append(result_iteration)
            if timer.is_alive():
                timer.cancel()
                timer.join()
            timer = threading.Timer(60.0, prg.interrupt)
            if sum(m.cost) < sum(local_best_solution):
                local_best_solution = m.cost
            if not timer.is_alive():
                timer.start()

    i = 0
    ret = None
    solution_found = False
    all_time_best = [float('inf')]
    iteration_without_improvement = 0
    current_best_solution = float('inf')
    results = []
    start = time.time()
    while (not solution_found or iteration_without_improvement < 3):
        timer = threading.Timer(60.0, prg.interrupt)
        local_best_solution = [float('inf')]
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
        prg.cleanup()
        prg.ground(parts)
        timer.start()
        ret = prg.solve(on_model=handle_stop)
        if sum(local_best_solution) < sum(all_time_best):
            all_time_best = local_best_solution
            solution_found = True
            if len(all_time_best) > 1:
                prg.configuration.solve.opt_mode = "opt,{},{}".format(all_time_best[0], all_time_best[1])
            else:
                prg.configuration.solve.opt_mode = "opt,{}".format(all_time_best[0])
            iteration_without_improvement = 0
        else:
            iteration_without_improvement += 1
        i += 1
        if timer.is_alive():
            timer.cancel()
            timer.join()
    df = pd.DataFrame(results, columns=['Time', 'Cost'])
    now = datetime.datetime.now()
    date_string = now.strftime("%d_%m_%Y_%H_%M_%S")
    results_path = "results/parallel/"
    if not os.path.exists(results_path):
        os.mkdir(results_path)
    df.to_csv(results_path + "time_" + date_string + ".csv")
#end.

#program step(t).
