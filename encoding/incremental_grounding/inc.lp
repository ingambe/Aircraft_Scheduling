#script (python) 

import clingo
import sys

def main(prg):

    
    def cost_output(m):
        #print("Solution cost is {}".format(m.cost[0]))
        nonlocal solution_cost
        nonlocal stop
        if m.cost[0] == solution_cost:
            #prg.interrupt()
            stop = True
        solution_cost = m.cost[0]


    istop  = clingo.String("SAT")

    i = 0
    ret = None

    solution_cost = -1
    stop = False

    while (not stop  or (
              (istop.string == "SAT"     and not ret.satisfiable) or
              (istop.string == "UNSAT"   and not ret.unsatisfiable) or 
              (istop.string == "UNKNOWN" and not ret.unknown))):
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
        prg.ground(parts)
        i += 1
        ret = prg.solve(on_model=cost_output)
        #ret = prg.solve()
#end.

#program step(t).