#!/usr/bin/env python

from lark import Lark
import sys



def asp_to_solution(input_file_content, solution_file_content):
    max_flight = 0
    max_aircraft = 0

    grammar = """
    start: expr

    expr:  "aircraft(" NUMBER ".." NUMBER ")."
        | 

    %import common.NUMBER
    %ignore " "
    """

    l = Lark(grammar)

    solution_file_content = solution_file_content.split()
    grammar = """
    start: expr

    expr:  "assign(" NUMBER "," NUMBER ")"

    %import common.NUMBER
    %ignore " "
    """

    l = Lark(grammar)
    for assignment in solution_file_content:
        tree = l.parse(assignment)
    print( l.parse(solution_file_content[0]) )

if __name__== "__main__":
    if len(sys.argv) > 2:
        solution_file = sys.argv[1]
        solution = open(solution_file, "r")
        for line in solution:
            # we get online the line with the solution
            if line[:7] == "assign(":
                asp_to_solution(line)
    else:
        print("Error: You need to specify an input file containing the input problem and the produced solution")