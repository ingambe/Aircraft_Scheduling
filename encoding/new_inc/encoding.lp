%%%%%%%%%%%%%%%%%%%%%%%%%%% FLIGHT ALLOCATION %%%%%%%%%%%%%%%%%%%%%%%%%%%

{route(F1, F2) : compatible(F1, F2, T)} 1 :- flight(F1).
{route(F1, F2) : compatible(F1, F2, T)} 1 :- flight(F2).

assign(F, A) :- first(F, A).
assign(F2, A) :- assign(F1, A), aircraft(A), route(F1, F2), not first(F2, A).

%:~ C = #count{F : flight(F), not assign(F, _)}. [C]

:- flight(F), #count{A : assign(F, A)} != 1.

%%%%%%%%%%%%%%%%%%%%%%%%%%% MAINTENANCE %%%%%%%%%%%%%%%%%%%%%%%%%%%

maintenance_compatible_flight(F, M) :- airport_maintenance(M, A), airport_end(F, A).
maintenance_compatible_route(F1, F2, M) :- maintenance_compatible_flight(F1, M), compatible(F1, F2, T), length_maintenance(M, LM), T >= LM.

{maintenance_after_flight(F1, M)} :- maintenance_compatible_route(F1, F2, M).

maintenance_coverage(F1, M) :- first(F1, A), maintenance(M).
maintenance_coverage(F2, M) :- first(F1, A), assign(F2, A), start_maintenance_counter(M, A, C), limit_counter(M, L), end(F1, S1), LEFT = L - C, end(F2, S2), B = S2 - S1, B <= LEFT, S1 < S2.
maintenance_coverage(F2, M) :- assign(F1, A), assign(F2, A), end(F1, T1), end(F2, T2), T1 < T2, maintenance_after_flight(F1, M), TIME = T2 - T1, limit_counter(M, L), TIME <= L.

%:- flight(F), maintenance(M), not maintenance_coverage(F, M).

%%%%%%%%%%%%%%%%%%%%%%%%%%% OPTIMISATION %%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% TAT
violation_tat(F1, F2, T) :- route(F1, F2), compatible(F1, F2, T), T < 0.

%:~ violation_tat(F1, F2, T), cost(tat, C). [C, F1]

computed_cost(tat, T * C) :- #count{F: violation_tat(F, _, _)} = T, cost(tat, C).

:~ computed_cost(tat, C). [C@2]

%%% MAINTENANCE

computed_cost(maintenance, T * 101) :- #count{F: maintenance_after_flight(F, _)} = T.

:~ computed_cost(maintenance, C). [C@1]


%%%%%%%%%%%%%%%%%%%%%%%%%%% SHOW %%%%%%%%%%%%%%%%%%%%%%%%%%%

#show assign/2.
%#show maintenance_after_flight/2.
%#show compatible/3.
%#show route/2.

%*
ddd
*%

#external compatible(F1, F2, T2 - T1 - TAT): end(F1, T1), start(F2, T2), airport_end(F1, A1), airport_start(F2, A1), T1 < T2, tat(F1, TAT).

#script (python)

import clingo
import sys
import threading
import time
import copy

def main(prg):

    # we stop if we have two time in a row the same cost
    # for performance only, can be deactivated
    def handle_stop(m):
        """ This function keep track of the global best solution and the current iteration best solution
        It also handles the timer in order to stop if we don't find a solution after 60 second in the current iteration """
        nonlocal current_best_solution
        nonlocal timer
        if len(m.cost) > 0:
            if timer.is_alive():
                timer.cancel()
                timer.join()
            timer = threading.Timer(60.0, prg.interrupt)
            if m.cost[0] < current_best_solution:
                current_best_solution = m.cost[0]
            if not timer.is_alive():
                timer.start()

    i = 0
    ret = None
    best_solutions = []
    all_time_best = 999999999
    iteration_without_improvement = 0
    while (len(best_solutions) < 1 or iteration_without_improvement < 3) and (ret is None or not ret.satisfiable):
        timer = threading.Timer(3600.0, prg.interrupt)
        timer.start()
        current_best_solution = float('inf')
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
        prg.ground(parts)
        iteration_without_improvement += 1
        ret = prg.solve(on_model=handle_stop)
        if current_best_solution < all_time_best:
            all_time_best = current_best_solution
            best_solutions.append(current_best_solution)
            iteration_without_improvement = 0
        i += 1
        #print("Current best {}".format(min(best_solutions)))
        if timer.is_alive():
            timer.cancel()
            timer.join()
#end.

#program step(t).

compatible(F1, F2, T - TAT) :- end(F1, T1), start(F2, T2), airport_end(F1, A1), airport_start(F2, A1), T1 < T2, not first(F2, _), tat(F1, TAT), T = T2 - T1, (t-1) * 3600 <= T, T < t * 3600.
