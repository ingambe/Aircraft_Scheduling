#script (python) 

import clingo
import sys

def main(prg):
    
    # we stop if we have two time in a row the same cost
    # for performance only, can be desactivated
    def handle_stop(m):
        #print("Solution cost is {}".format(m.cost[0]))
        nonlocal current_best_solution
        if m.cost[0] < current_best_solution:
            current_best_solution = m.cost[0]

    istop  = clingo.String("SAT")

    i = 0
    ret = None

    best_solutions = []
    stop = False

    while ((len(best_solutions) < 2 or best_solutions[-2] != best_solutions[-1])  or (
              (istop.string == "SAT"     and not ret.satisfiable) or
              (istop.string == "UNSAT"   and not ret.unsatisfiable) or 
              (istop.string == "UNKNOWN" and not ret.unknown))):
        current_best_solution = float('inf')
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
        prg.ground(parts)
        i += 1
        ret = prg.solve(on_model=handle_stop)
        best_solutions.append(current_best_solution)
#end.

#program step(t).