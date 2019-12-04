#!/usr/bin/env python

import os
import argparse
import clyngor

def main():
    parser = argparse.ArgumentParser(description='Generate the solution and test it to ensure it is correct')
    parser.add_argument('--instance', type=str, help="the path to the instance")
    parser.add_argument('--encoding', type=str, help="the path to the encoding")    
    parser.add_argument('--output_file', type=str, help="the path to the ouput file")
    args = parser.parse_args()
    instance = args.instance
    encoding = args.encoding
    output_file = "solution_" + instance.split("/")[-1]
    if args.output_file != None:
        output_file =  args.output_file
    answers = clyngor.solve(files=[instance, encoding])
    solutions = [answer for answer in answers]
    assert len(solutions) > 0, "there is no solution"
    assert len(solutions) != 1, "there may have multiple solutions but we want just one solution"
    print("There is a solution, but is it a correct one ? Let's find out !")
    for answer in solutions:
        asp_str = ' '.join(clyngor.utils.generate_answer_set_as_str(answer, atom_end='.'))
        test_correctness = clyngor.solve(inline = asp_str, files=[os.path.dirname(os.path.realpath(__file__)) +"/test_solution.lp", instance])
        corrects = [correct for correct in test_correctness]
        assert len(corrects) > 0, "the solution is incorrect !"
        print("The solution generated is correct ! :O")
        file = open(output_file, "w+")
        file.write(asp_str)
        file.close()
    


if __name__== "__main__":
      main()