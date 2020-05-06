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
        nonlocal local_best_solution
        nonlocal timer
        if len(m.cost) > 0:
            if timer.is_alive():
                timer.cancel()
                timer.join()
            timer = threading.Timer(60.0, prg.interrupt)
            if sum(m.cost) < sum(local_best_solution):
                local_best_solution = m.cost
            if not timer.is_alive():
                timer.start()

    i = 0
    max_number_atom = 0
    iteration_between_two_new_atom = 100
    ret = None
    solution_found = False
    all_time_best = [float('inf')]
    iteration_without_improvement = 0
    current_best_solution = float('inf')
    while (not solution_found or iteration_without_improvement < 3) and iteration_between_two_new_atom > 0:
        timer = threading.Timer(60.0, prg.interrupt)
        #iteration_between_two_new_atom -= 1
        local_best_solution = [float('inf')]
        parts = []
        parts.append(("step", [i]))
        if i == 0:
            parts.append(("base", []))
        prg.cleanup()
        prg.ground(parts)
        number_atom = 0
        for x in prg.symbolic_atoms.by_signature("compatible", 3):
            if x.is_fact:
                number_atom += 1
        # if we have new atoms, we reset the counter of new atoms before stopping
        if number_atom > max_number_atom:
            timer.start()
            max_number_atom = number_atom
            iteration_between_two_new_atom = 100
            ret = prg.solve(on_model=handle_stop)
            if sum(local_best_solution) < sum(all_time_best):
                all_time_best = local_best_solution
                solution_found = True
                if len(all_time_best) > 1:
                    prg.configuration.solve.opt_mode = "opt,{},{}".format(all_time_best[0], all_time_best[1])
                else:
                    prg.configuration.solve.opt_mode = "opt,{}".format(all_time_best[0])

                iteration_without_improvement = 0
            else:
                iteration_without_improvement += 1
        i += 1
        if timer.is_alive():
            timer.cancel()
            timer.join()
#end.

#program step(t).