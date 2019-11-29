#script (python) 

import clingo

def main(prg):
    stepinc   = prg.get_const("stepinc").number
    istop  = clingo.String("SAT")

    i = 0
    step, ret = stepinc, None
    while (step == stepinc  or (
              (istop.string == "SAT"     and not ret.satisfiable) or
              (istop.string == "UNSAT"   and not ret.unsatisfiable) or 
              (istop.string == "UNKNOWN" and not ret.unknown))):
        parts = []
        parts.append(("check", [step]))
        if step > stepinc:
            prg.release_external(clingo.Function("query", [step-1]))
            parts.append(("step", [step]))
            prg.cleanup()
        else:
            parts.append(("base", []))
        prg.ground(parts)
        i += 1
        ret, step = prg.solve(), step + stepinc
#end.

#program check(t).