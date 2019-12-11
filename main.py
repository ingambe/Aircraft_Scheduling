#!/usr/bin/env python

import os
import argparse
import clyngor

def asp_to_solution(instance, frozenset):
    return null

def main():
    parser = argparse.ArgumentParser(description='Generate the solution and test it to ensure it is correct')
    parser.add_argument('--instance', type=str, help="the path to the instance")
    parser.add_argument('--encoding', type=str, help="the path to the encoding")    
    parser.add_argument('--output_file', type=str, help="the path to the ouput file")
    parser.add_argument('--gannt', action='store_true', help="show the gannt")
    parser.add_argument('-n', type=int, help="number of solution to get (default = 1)")
    parser.add_argument('-q', action='store_true', help="quiet mode, doesn't print the solution")
    args = parser.parse_args()
    instance = args.instance
    encoding = args.encoding
    if args.output_file != None:
        output_file =  args.output_file
    nb_solution = 1
    if args.n != None:
        nb_solution = args.n
    answers = clyngor.solve(files=[instance, encoding], nb_model=nb_solution)
    solutions = [answer for answer in answers]
    if len(solutions) == 0:
        print("There is no solution !")
    else:
        print("There is a solution, but is it a correct one ? Let's find out !")
        i = 0
        for answer in solutions:
            asp_str = ' '.join(clyngor.utils.generate_answer_set_as_str(answer, atom_end='.'))
            if args.q == None:
                print(asp_str)
            test_correctness = clyngor.solve(inline = asp_str, files=["test_solution/test_solution.lp", instance])
            corrects = [correct for correct in test_correctness]
            if len(corrects) > 0:
                print("The solution generated is correct ! :O")
                if len(solutions) > 1:
                    output_file = "solution_" + i + "_" + instance.split("/")[-1]
                else:
                    output_file = "solution_" + instance.split("/")[-1]
                file = open(output_file, "w+")
                file.write(asp_str)
                file.close()
                if args.gannt:
                    solution_model = asp_to_solution(instance, answer)
            else:
                print("The solution generated is INCORRECT ! :'(")
                output_file = "incorrect_solution_" + i + "_" + instance.split("/")[-1]
                file = open(output_file, "w+")
                file.write(asp_str)
                file.close()
            i += 1

if __name__== "__main__":
      main()