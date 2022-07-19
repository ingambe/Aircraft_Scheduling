#const stepinc = 60.

#const chunk_rel_size = 70.

#const weight_maintenance = 101.
#const level_maintenance = 1.

#const weight_tat = 500.
#const level_tat = 2.

#program base.

flight(F, A, S, B, T) :- flight(F),
                         airport_start(F, A), start(F, S),
                         airport_end(F, B), end(F, T).
flight(B, T)          :- flight(F, A, S, B, T).

fixed(F, A, S, B, T, P) :- flight(F, A, S, B, T), first(F, P).
fixed(B, T)             :- fixed(F, A, S, B, T, P).

range(F, A, S, B, T) :- flight(F, A, S, B, T), not fixed(F, _, _, _, _, _).
range(S, T)          :- range(F, A, S, B, T).
range(S)             :- range(S, T).

depart(A, S) :- range(F, A, S, B, T).
depart(B, T) :- arrive(B, T).
depart(A)    :- depart(A, S).

arrive(F, B, T)   :- flight(F, A, S, B, T), depart(B).
arrive(B, T)      :- arrive(F, B, T).
index(F, B, T, I) :- arrive(F, B, T), I = #count{G : arrive(G, B, T), G <= F}.

gather(@insert(B, T)) :- depart(B, T).

next_time(A, T, S) :- gather(A), (T, S) = @order(A).

number(A, T, N) :- depart(A, T),
                   N = #sum{ 1, F : arrive(F, A, T);
                            -1, F : range(F, A, T, B, S)}.

ac_count(B, T, N)     :- number(B, T, N),
                         T1 >= T : flight(B, T1).

ac_count(A, S, C + N) :- ac_count(A, T, C),
                         next_time(A, T, S),
                         number(A, S, N).

zero_instant(B, T) :- ac_count(B, T, 0).

tmp_arrive(F, B, T2) :- next_time(B, T1, T2), index(F, B, T1, 1).
tmp_arrive(F, B, T2) :- next_time(B, T1, T2), tmp_arrive(F, B, T1), not zero_instant(B, T1), not arrive(B, T1).

prev_flight(F1, F2, B) :- tmp_arrive(F1, B, T), index(F2, B, T, I), not index(_, B, T, I+1).
prev_flight(F1, F2, B) :- index(F1, B, T, I + 1), index(F2, B, T, I).

tmp_depart(A, S, S) :- range(F, A, S, B, T).
tmp_depart(A, S, T) :- tmp_depart(A, S, X), next_time(A, T, X), not arrive(A, X).

distance(F, G, 0) :- range(F, A, S, B, T), tmp_depart(A, S, X), index(G, A, X, 1).
distance(F, G, N) :- distance(F, H, N-1), prev_flight(G, H, B).

chunk_size(F, @chunk_size(TOT + 1, chunk_rel_size)) :- range(F, A, S, T, B),
                                                       TOT = #max{N : distance(F, _, N)}.

compatible(F1, B, T1, F2, G, N/CS + 1) :- distance(F2, F1, N),
                                                  flight(F1, A, S1, B, T1),
                                                  range(F2, B, S2, C, T2),
                                                  chunk_size(F2, CS),
                                                  G = S2 - T1.
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
import math

schedule = { }

def insert(airport, time):
    if airport not in schedule:
        schedule[airport] = [ ]
    schedule[airport].append(time)
    return airport

def order(airport):
    schedule[airport].sort()
    result = [ ]
    for i in range(len(schedule[airport]) - 1):
        result.append(clingo.Function("", [schedule[airport][i], schedule[airport][i + 1]]))
    return result

def chunk_size(tot, rel_size):
    n_tot = tot.number
    n_rel_size = rel_size.number
    result = math.ceil(n_tot / n_rel_size)
    return clingo.Number(result)

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
    timings_iter = []
    start = time.time()
    while (not solution_found or iteration_without_improvement < 3):
        start_iter = int(time.time() - start)
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
        end_iter = int(time.time() - start)
        timings_iter.append([i, start_iter, end_iter, solution_found, all_time_best[len(all_time_best) - 1]])
        i += 1
        if timer.is_alive():
            timer.cancel()
            timer.join()
    df = pd.DataFrame(results, columns=['Time', 'Cost'])
    df_iter = pd.DataFrame(timings_iter, columns=['Iteration', 'Starting time', 'Ending time', 'Solution found', 'Cost'])
    now = datetime.datetime.now()
    date_string = now.strftime("%d_%m_%Y_%H_%M_%S")
    results_path = "results/inc_chunks_rel_70/"
    if not os.path.exists(results_path):
        os.mkdir(results_path)
    inst = str(prg.get_const("instance"))
    if inst == None:
        df.to_csv(results_path + "time_" + date_string + ".csv")
        df_iter.to_csv(results_path + "iter_" + date_string + ".csv")
    else:
        df.to_csv(results_path + "time_" + inst + ".csv")
        df_iter.to_csv(results_path + "iter_" + inst + ".csv")

#end.



#program step(t).