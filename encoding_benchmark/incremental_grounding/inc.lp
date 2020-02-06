#script (python) 

import clingo
import sys

def main(prg):

    istop  = clingo.String("SAT")

    i = 0
    ret = None

    #initial_ground = initial_ground()
    
    def cost_output(m):
        print("Cost is {}".format(m.cost[0]))
        if m.cost[0] == 0:
            print("STOP")
            prg.interrupt()

    while (i == 0  or (
              (istop.string == "SAT"     and not ret.satisfiable) or
              (istop.string == "UNSAT"   and not ret.unsatisfiable) or 
              (istop.string == "UNKNOWN" and not ret.unknown))):
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
        prg.ground(parts)
        i += 1
        #ret = prg.solve(on_model=cost_output)
        ret = prg.solve()
#end.

#program step(t).