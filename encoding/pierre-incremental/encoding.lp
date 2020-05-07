#const second_inc=600.

#const weight_maintenance = 101.
#const level_maintenance = 1.

#const weight_tat = 500.
#const level_tat = 2.

%%%%%%%%%%%%%%%%%%%%%%%%%%% FLIGHT ALLOCATION %%%%%%%%%%%%%%%%%%%%%%%%%%%

{route(F1, F2) : compatible(F1, F2, T)} 1 :- flight(F1).
{route(F1, F2) : compatible(F1, F2, T)} 1 :- flight(F2).

assign(F, A) :- first(F, A).
assign(F2, A) :- assign(F1, A), aircraft(A), route(F1, F2), not first(F2, A).

:- flight(F), #count{A : assign(F, A)} != 1.

%%%%%%%%%%%%%%%%%%%%%%%%%%% MAINTENANCE %%%%%%%%%%%%%%%%%%%%%%%%%%%

maintenance_compatible_flight(F, M) :- airport_maintenance(M, A), airport_end(F, A).
maintenance_compatible_route(F1, F2, M) :- maintenance_compatible_flight(F1, M), compatible(F1, F2, T), length_maintenance(M, LM), T >= LM.

{maintenance_after_flight(F1, M)} :- maintenance_compatible_route(F1, F2, M).

maintenance_coverage(F1, M) :- first(F1, A), maintenance(M).
maintenance_coverage(F2, M) :- first(F1, A), assign(F2, A), start_maintenance_counter(M, A, C), limit_counter(M, L), end(F1, S1), LEFT = L - C, end(F2, S2), B = S2 - S1, B <= LEFT, S1 < S2.
maintenance_coverage(F2, M) :- assign(F1, A), assign(F2, A), end(F1, T1), end(F2, T2), T1 < T2, maintenance_after_flight(F1, M), TIME = T2 - T1, limit_counter(M, L), TIME <= L.

:- flight(F), maintenance(M), not maintenance_coverage(F, M).

%%%%%%%%%%%%%%%%%%%%%%%%%%% OPTIMISATION %%%%%%%%%%%%%%%%%%%%%%%%%%%

cost(tat, weight_tat, level_tat).
cost(maintenance, weight_maintenance, level_maintenance).

:~ route(F1, F2), compatible(F1, F2, T), T < 0, cost(tat, C, L). [C@L, F1, tat]

:~ maintenance_after_flight(F, M), cost(maintenance, C, L). [C@L, F, maintenance]

%%%%%%%%%%%%%%%%%%%%%%%%%%% SHOW %%%%%%%%%%%%%%%%%%%%%%%%%%%

#show assign/2.
#show maintenance_after_flight/2.

#external compatible(F1, F2, T2 - T1 - TAT) : end(F1, T1), tat(F1, TAT), start(F2, T2), airport_end(F1, A1), airport_start(F2, A1), T1 < T2.

#script (python)

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
            seconds = time.time() - start
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
    max_number_atom = 0
    iteration_between_two_new_atom = 100
    ret = None
    solution_found = False
    all_time_best = [float('inf')]
    iteration_without_improvement = 0
    current_best_solution = float('inf')
    results = []
    start = time.time()
    while (not solution_found or iteration_without_improvement < 3) and iteration_between_two_new_atom > 0:
        timer = threading.Timer(60.0, prg.interrupt)
        #iteration_between_two_new_atom -= 1
        local_best_solution = [float('inf')]
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
        prg.cleanup()
        prg.ground(parts)
        number_atom = 0
        for x in prg.symbolic_atoms.by_signature("compatible", 3):
            if x.is_fact:
                number_atom += 1
        # if we have new atoms, we reset the counter of new atoms before stopping
        if number_atom > max_number_atom:
            timer.start()
            max_number_atom = number_atom
            iteration_between_two_new_atom = 100
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
    df.to_csv("results/pierre_inc_" + date_string + ".csv")
#end.

#program step(t).

compatible(F1, F2, T - TAT) :- end(F1, T1), tat(F1, TAT), start(F2, T2), airport_end(F1, A1), airport_start(F2, A1), T1 < T2, not first(F2, _), T = T2 - T1, (t-1) * second_inc <= T, T < t * second_inc.