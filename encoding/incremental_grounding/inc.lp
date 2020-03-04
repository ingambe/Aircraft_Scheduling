#script (python) 

import clingo
import sys
from threading import Thread
import time

def main(prg):

    counter = 0
    stop = False

    def kill_search():
        nonlocal stop
        nonlocal counter
        while counter < 60:
            time.sleep(1)
            counter += 1
            #print("counter {}".format(counter))
        prg.interrupt()
        stop = True

    # we stop if we have two time in a row the same cost
    # for performance only, can be desactivated
    def handle_stop(m):
        #print("Solution cost is {}".format(m.cost[0]))
        nonlocal current_best_solution
        nonlocal counter
        nonlocal p
        if not p.is_alive() and counter < 60:
            print("OKAY START {}".format(counter))
            p.start()
        counter = 0
        if m.cost[0] < current_best_solution:
            current_best_solution = m.cost[0]

    i = 0
    ret = None

    best_solutions = []
    p = Thread(target=kill_search)
    while ((len(best_solutions) < 2 or best_solutions[-2] != best_solutions[-1])  or not ret.satisfiable) and not stop:
        counter = 0
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