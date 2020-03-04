#script (python) 

import clingo
import sys
from threading import Thread
import time

def main(prg):

    launched = False
    to_stop_current_it = False


    counter = 0

    best_solution = None

    def kill_search():
        nonlocal counter
        nonlocal to_stop_current_it
        while counter < 60:
            time.sleep(1)
            counter += 1
            print("counter {}".format(counter))
        to_stop_current_it = True
        prg.interrupt()

    # we stop if we have two time in a row the same cost
    # for performance only, can be deactivated
    def handle_stop(m):
        nonlocal current_best_solution
        nonlocal best_solution
        nonlocal counter
        nonlocal to_stop_current_it
        if not to_stop_current_it:
            if m.cost[0] < current_best_solution:
                current_best_solution = m.cost[0]
                best_solution = m
            counter = 0
            if not p.is_alive():
                print("OKAY START")
                p.start()
                launched = True

    i = 0
    ret = None

    best_solutions = []
    p = Thread(target=kill_search)
    while ((len(best_solutions) < 2 or best_solutions[-2] >= best_solutions[-1])  or not ret.satisfiable):
        p = Thread(target=kill_search)
        to_stop_current_it = False
        launched = False
        counter = 0
        stop = False
        current_best_solution = float('inf')
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
        prg.ground(parts)
        i += 1
        ret = prg.solve(on_model=handle_stop)
        best_solutions.append(current_best_solution)
        if p.is_alive():
            p.terminate()
            p.join()
#end.

#program step(t).