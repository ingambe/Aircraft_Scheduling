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
    all_time_best = [None, float('inf')]
    while ((len(best_solutions) < 3 or best_solutions[-3] >= best_solutions[-1]) and (ret is None or not ret.satisfiable)) or i < 20:
        timer = threading.Timer(60.0, prg.interrupt)
        timer.start()
        current_best_solution = float('inf')
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
        prg.ground(parts)
        i += 1
        ret = prg.solve(on_model=handle_stop)
        best_solutions.append(current_best_solution)
        if timer.is_alive():
            timer.cancel()
            timer.join()
#end.

#program step(t).