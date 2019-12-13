#!/usr/bin/env python

import os
import argparse
import clyngor
import re
import sys

sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), 'instance_generator/models')))

from Flight import *
from Solution import *
sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), 'instance_generator')))
import route_gen

def gantt_solution(instance, solution):
    '''
    We take the str of the instance and the solution as input
    We then parse it and create a gantt
    '''
    # first remove annoying whitespace
    instance = instance.replace(" ", "")
    solution = solution.replace(" ", "")
    # some regex to parse the data
    aircraft_regex = re.compile(r'aircraft\([0-9]+\)')
    airport_regex = re.compile(r'airport\([0-9]+\)')
    flight_regex = re.compile(r'flight\([0-9]+\)')
    first_regex = re.compile(r'first\([0-9]+,[0-9]+\)')
    airport_start_regex = re.compile(r'airport_start\([0-9]+,[0-9]+\)')
    airport_end_regex = re.compile(r'airport_end\([0-9]+,[0-9]+\)')
    start_regex = re.compile(r'[^_]start\([0-9]+,[0-9]+\)')
    end_regex = re.compile(r'[^_]end\([0-9]+,[0-9]+\)')
    tat_regex = re.compile(r'tat\([0-9]+,[0-9]+\)')
    assign_regex = re.compile(r'assign\([0-9]+,[0-9]+\)')
    # utility for the parsing of inside each rule
    number_regex = re.compile(r'[0-9]+')
    # we start with the flights
    flights_string = flight_regex.findall(instance)
    number_flights = len(flights_string)
    # we get the airport start
    airports_start = [-1 for i in range(number_flights)]
    parsed = airport_start_regex.findall(instance)
    for parse in parsed:
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        airports_start[numbers[0] - 1] = numbers[1]
    # then we get the airport end
    airports_end = [-1 for i in range(number_flights)]
    parsed = airport_end_regex.findall(instance)
    for parse in parsed:
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        airports_end[numbers[0] - 1] = numbers[1]
    # then we get the start
    start = [-1 for i in range(number_flights)]
    parsed = start_regex.findall(instance)
    for parse in parsed:
        #print("start {}".format(parse))
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        start[numbers[0] - 1] = numbers[1]
    # then we get the end
    end = [-1 for i in range(number_flights)]
    parsed = end_regex.findall(instance)
    for parse in parsed:
        #print("end {}".format(parse))
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        end[numbers[0] - 1] = numbers[1]
    # then we get the tat
    tat = [-1 for i in range(number_flights)]
    parsed = tat_regex.findall(instance)
    for parse in parsed:
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        tat[numbers[0] - 1] = numbers[1]
    # we need to get the aircraft assigned to
    fligth_aircraft_assigned = [-1 for i in range(number_flights)]
    parsed = assign_regex.findall(solution)
    for parse in parsed:
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        fligth_aircraft_assigned[numbers[0] - 1] = numbers[1] - 1
    # we have now enought information to build the fligths objects
    flights = [None for x in range(number_flights)]
    for i in range(number_flights):
        length_flight = end[i] - start[i]
        flight = Flight(i + 1, start[i], length_flight, airports_start[i], airports_end[i], fligth_aircraft_assigned[i], tat[i])
        flights[i] = flight
    
    #print("flights {}".format(flights))    
    # now the solution model
    parsed = aircraft_regex.findall(instance)
    number_aircrafts = len(parsed)
    parsed = airport_regex.findall(instance)
    number_airports = len(parsed)
    # we get now the first flight assign to each aircraft
    first_flight_assigned = [None for i in range(number_aircrafts)]
    parsed = first_regex.findall(instance)
    for parse in parsed:
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        first_flight_assigned[numbers[1] - 1] = flights[numbers[0] - 1]
    solution = Solution(number_aircrafts, number_airports, flights, first_flight_assigned)
    route_gen.gannt(solution)


def main():
    parser = argparse.ArgumentParser(description='Generate the solution and test it to ensure it is correct')
    parser.add_argument('--instance', type=str, help="the path to the instance")
    parser.add_argument('--encoding', type=str, help="the path to the encoding")    
    parser.add_argument('--output_file', type=str, help="the path to the ouput file")
    parser.add_argument('--gantt', action='store_true', help="output the gannt of the solution")
    parser.add_argument('--all', action='store_true', help="output all the solution")
    args = parser.parse_args()
    instance = args.instance
    encoding = args.encoding
    output_file = "solution_" + instance.split("/")[-1]
    if args.output_file != None:
        output_file =  args.output_file
    if args.all != None:
        answers = clyngor.solve(files=[instance, encoding])
    else:
        answers = clyngor.solve(files=[instance, encoding], nb_model=1)    
    answers = clyngor.solve(files=[instance, encoding])
    solutions = [answer for answer in answers]
    if len(solutions) == 0:
        print("There is no solution")
    print("There is a solution, but is it a correct one ? Let's find out !")
    for answer in solutions:
        asp_str = ' '.join(clyngor.utils.generate_answer_set_as_str(answer, atom_end='.'))
        test_correctness = clyngor.solve(inline = asp_str, files=[os.path.dirname(os.path.realpath(__file__)) +"/test_solution/test_solution.lp", instance])
        corrects = [correct for correct in test_correctness]
        if len(corrects) == 0 : 
            print("the solution is incorrect !")
        else:
            print("The solution generated is correct ! :O")
        file = open("solutions/" + output_file, "w+")
        file.write(asp_str)
        file.close()
        if args.gantt:
            instances_sol = clyngor.solve(files=[instance], wait=True)
            for instance_sol in instances_sol:
                instance_str = ''.join(clyngor.utils.generate_answer_set_as_str(instance_sol, atom_end='.'))
                gantt_solution(instance_str, asp_str)

if __name__== "__main__":
      main()