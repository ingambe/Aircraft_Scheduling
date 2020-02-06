#script (python) 

import clingo
import sys

def main(prg):


    stepinc   = prg.get_const("stepinc").number
    istop  = clingo.String("SAT")

    i = 0
    ret = None

    
    def cost_output(m):
        print("Cost is {}".format(m.cost))
        if m.cost[0] == 39000:
            print("STOP")
            sys.exit(0)

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
        ret = prg.solve(on_model=cost_output)
#end.

#program step(t).