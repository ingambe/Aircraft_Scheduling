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
    all_time_best = 999999999999
    iteration_without_improvement = 0
    while (len(best_solutions) < 3) and (ret is None or not ret.satisfiable):
        timer = threading.Timer(3600.0, prg.interrupt)
        timer.start()
        current_best_solution = float('inf')
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
            #parts.append(("best", [5000]))
        prg.add("base", [], "best({}).".format(all_time_best))
        prg.ground(parts)
        iteration_without_improvement += 1
        ret = prg.solve(on_model=handle_stop)
        if current_best_solution < all_time_best:
            all_time_best = current_best_solution
            best_solutions.append(current_best_solution)
            #prg.add("base", [], "best({}).".format(all_time_best))
            iteration_without_improvement = 0
        i += 1
        #print("Current best {}".format(min(best_solutions)))
        if timer.is_alive():
            timer.cancel()
            timer.join()
#end.

#program step(t).