#!/usr/bin/env python
import json
import os
import argparse
import re
import sys
import tempfile
import time
from os.path import basename

sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), 'instance_generator/models')))

from Flight import *
from Solution import *
sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), 'instance_generator')))
import route_gen
import subprocess


def gantt_solution(instance, solution):
    '''
    We take the str of the instance and the solution as input
    We then parse it and create a gantt
    '''
    # first remove annoying whitespace
    instance = instance.replace(" ", "")
    solution = solution.replace(" ", "")


    # utility for the parsing of inside each rule
    number_regex = re.compile(r'[0-9]+')
    # some regex to parse the data
    aircraft_regex = re.compile(r'aircraft\([0-9]+\)')
    airport_regex = re.compile(r'airport\([0-9]+\)')
    flight_regex = re.compile(r'flight\([0-9]+\)')
    first_regex = re.compile(r'first\([0-9]+,[0-9]+\)')
    airport_start_regex = re.compile(r'airport_start\([0-9]+,[0-9]+\)')
    airport_end_regex = re.compile(r'airport_end\([0-9]+,[0-9]+\)')
    start_regex = re.compile(r'start\([0-9]+,[0-9]+\)')
    end_regex = re.compile(r'end\([0-9]+,[0-9]+\)')
    tat_regex = re.compile(r'tat\([0-9]+,[0-9]+\)')
    assign_regex = re.compile(r'assign\([0-9]+,[0-9]+\)')
    maintenance_regex = re.compile(r'maintenance_after_flight\([0-9]+,[0-9]+\)')
    length_maintenance_regex = re.compile(r'length_maintenance\(seven_day,[0-9]+\)')
    maintenance_length = dict()
    if len(length_maintenance_regex.findall(instance)) > 0:
        maintenance_length["seven_day"] = int(number_regex.findall(length_maintenance_regex.findall(instance)[0])[0])

    airport_maintenance_regex = re.compile(r'airport_maintenance\(seven_day,[0-9]+\)')
    airport_maintenance = airport_maintenance_regex.findall(instance)
    airport_maintenance_int = [int(number_regex.findall(x)[0]) for x in airport_maintenance]


    limit_counter_regex = re.compile(r'limit_counter\(seven_day,[0-9]+\)')
    limit_counter = limit_counter_regex.findall(instance)
    limit_counter_dict = dict()
    if len(limit_counter) > 0:
        limit_counter_dict["seven_day"] = int(number_regex.findall(limit_counter[0])[0])

    # we start with the flights
    flights_string = flight_regex.findall(instance)
    number_flights = len(flights_string)

    start_maint_count = dict()

    airport_maintenance_regex = re.compile(r'start_maintenance_counter\(seven_day,[0-9]+,[0-9]+\)')
    parsed = airport_maintenance_regex.findall(instance)
    start_maint_count["seven_day"] = [0 for i in range(number_flights)]
    for parse in parsed:
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        start_maint_count["seven_day"][numbers[0] - 1] = numbers[1]



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
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        start[numbers[0] - 1] = numbers[1]
    # then we get the end
    end = [-1 for i in range(number_flights)]
    parsed = end_regex.findall(instance)
    for parse in parsed:
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
    maintenance_after_flight_assigned = [False for i in range(number_flights)]
    parsed = maintenance_regex.findall(solution)
    for parse in parsed:
        numbers = number_regex.findall(parse)
        numbers = [int(x) for x in numbers]
        maintenance_after_flight_assigned[numbers[0] - 1] = numbers[1]
    # we have now enought information to build the fligths objects
    flights = [None for x in range(number_flights)]
    for i in range(number_flights):
        length_flight = end[i] - start[i]
        flight = Flight(i + 1, start[i], length_flight, airports_start[i], airports_end[i], fligth_aircraft_assigned[i], tat[i])
        flights[i] = flight

    flights_created = dict()
    for i in range(number_flights):
        start_airport = airports_start[i]
        end_airport = airports_end[i]
        if not (start_airport, end_airport) in flights_created:
            flights_created[(start_airport, end_airport)] = flights[i]

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
    solution = Solution(number_aircrafts, number_airports, flights, first_flight_assigned, 500, 5000, flights_created, start_maint_count, limit_counter_dict, maintenance_length, airport_maintenance_int)
    route_gen.gannt(solution)


def main():
    parser = argparse.ArgumentParser(description='Generate the solution and test it to ensure it is correct')
    parser.add_argument('--instance', type=str, help="the path to the instance")
    parser.add_argument('--output_file', type=str, help="the path to the ouput file")
    parser.add_argument('--gantt', action='store_true', help="output the gannt of the solution")
    args = parser.parse_args()
    instance = args.instance
    output_file = "solution_" + instance.split("/")[-1]
    if args.output_file is not None:
        output_file =  args.output_file
    start = time.time()
    clingo = subprocess.Popen(["clingo"] + [instance] + ['encoding/incremental_grounding/inc.lp'] + ['encoding/incremental_grounding/encoding.lp'] + ["--outf=2"],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (stdoutdata, stderrdata) = clingo.communicate()
    clingo.wait()
    end = time.time()
    duration = end - start
    # print("out: {}".format(stdoutdata))
    # print("error: {}".format(stderrdata))
    # print(stdoutdata)
    json_answers = json.loads(stdoutdata)

    correct_solution = json_answers["Result"] == "SATISFIABLE" or json_answers["Result"] == "OPTIMUM FOUND"
    if correct_solution:
        print("There is a solution, but is it a correct one ? Let's find out !")
    else:
        print("There is no solution")
    cost = float('inf')
    call = json_answers["Call"][-1]
    answer = call["Witnesses"][-1]
    # we need to check all solution and get the best one
    for call_current in json_answers["Call"]:
        if "Witnesses" in call_current:
            answer_current = call_current["Witnesses"][-1]
            current_cost = answer_current["Costs"][0]
            if current_cost < cost:
                answer = answer_current
                cost = current_cost
    # we append "" just to get the last . when we join latter
    answer = answer["Value"] + [""]
    answer_str = ".".join(answer)
    answer_temp = tempfile.NamedTemporaryFile(mode="w+", suffix='.lp', dir=".", delete=False)
    answer_temp.write(answer_str)
    # this line is to wait to have finish to write
    answer_temp.flush()
    print(answer_temp.name)
    clingo_check = subprocess.Popen(["clingo"] + ["test_solution/test_solution.lp"] + [answer_temp.name] + [
                instance] + ["--outf=2"] + ["-q"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (stdoutdata_check, stderrdata_check) = clingo_check.communicate()
    clingo_check.wait()
    json_check = json.loads(stdoutdata_check)
    print("Best solution cost {}".format(cost))
    print(json_check)
    if not json_check["Result"] == "SATISFIABLE":
        correct_solution = False
    if correct_solution:
        print("The solution is correct")
    if args.gantt:
        clingo_facts_grounded = subprocess.Popen(
            ["clingo"] + [instance] + ["--outf=2"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        (stdoutdata_instance, stderrdata_instance) = clingo_facts_grounded.communicate()
        clingo.wait()
        json_answers = json.loads(stdoutdata_instance)
        call = json_answers["Call"][-1]
        answer = " ".join(call["Witnesses"][-1]["Value"])
        gantt_solution(answer, answer_str)




if __name__== "__main__":
      main()