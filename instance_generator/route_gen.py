#!/usr/bin/env python

import numpy as np
import pathlib
from scipy.stats import truncnorm
import random
import time
import sys
import pandas as pd
import plotly.figure_factory as ff
import datetime
import plotly.graph_objects as go
import math
import models
import argparse
from default_parameters import *


def injective_airport(start, end):
    ''' Injective function to map [0, nb_airport] -> [0, nb_airport]\start '''
    if end < start:
        return end
    return end + 1

def truncated_norm(minimum, maximum, mean, sd):
    ''' Used to general random number with a normal distribution '''
    return truncnorm(a = (minimum - mean) / sd, b = (maximum - mean) / sd, scale=sd, loc=mean).rvs(size=1).round().astype(int)[0]

def instance_generator(nb_aircraft = default_nb_aircraft,
        nb_airport = default_nb_airport,
        mean_length_flight = default_mean_length_flight,
        var_length_flight = default_var_length_flight,
        min_length_flight = default_min_length_flight,
        max_length_flight = default_max_length_flight,
        mean_flight_per_aicraft = default_mean_flight_per_aicraft,
        var_flight_per_aicraft = default_var_flight_per_aicraft,
        min_flight_per_aicraft = default_min_flight_per_aicraft,
        max_flight_per_aicraft = default_max_flight_per_aicraft,
        mean_tat = default_mean_tat,
        var_tat = default_var_tat,
        min_tat = default_min_tat,
        max_tat = default_max_tat,
        mean_on_ground = default_mean_on_ground,
        var_on_ground = default_var_on_ground,
        min_on_ground = default_min_on_ground,
        max_on_ground = default_max_on_ground,
        verbose = False):
    ''' This function generate a Solution model '''
    
    # all the flight created and allocated to an aircraft
    flights = []
    
    # represent all unique flight created (i.e. starting from airport A to airport B)
    flights_created = dict()

    # represent the first fligth of each aircraft in the gant (first before now)
    first_fligth_aircraft = [None for i in range(nb_aircraft)]

    time_now = time.time()

    flights_per_aircraft = [0 for i in range(nb_aircraft)]
    for aircraft in range(nb_aircraft):
        flights_per_aircraft[aircraft] = truncated_norm(min_flight_per_aicraft, max_flight_per_aicraft, mean_flight_per_aicraft, var_flight_per_aicraft)
        if verbose:
            print("For aircraft {} we have {} flights".format(aircraft, flights_per_aircraft[aircraft]))
        first_flight = True
        for i in range(flights_per_aircraft[aircraft]):
            # we define a length of the flight, multiply by 60 to convert from minute to second (EPOCH)
            length_fly = truncated_norm(min_length_flight, max_length_flight, mean_length_flight, var_length_flight) * 60
            # we compute the tat
            tat = truncated_norm(min_tat, max_tat, mean_tat, var_tat)

            # for the first flight, the start airport is to be choosed between [0, nb_airport]
            # also, as we don't have previous flight, we need to determine a start date
            if first_flight:
                if verbose:
                        print("First flight of aircraft {}, is {} - {}".format(i, start_airport, end_airport))
                start_airport = truncated_norm(1, nb_airport, math.ceil(nb_airport / 2), math.ceil(nb_airport / 4))
                end_airport = injective_airport(start_airport, truncated_norm(1, nb_airport - 1, math.ceil((nb_airport - 1) / 2), math.ceil((nb_airport - 1) / 4)))
                # multiply by 60 to convert from minute to second (epoch is in second)
                # this allow to have a normal distribution between the flight end a time now and the flight start at time now
                start_date = truncated_norm(time_now - length_fly, time_now + length_fly, time_now, time_now / 4)
            else:
                # we recover the previous fligth (last added)
                previous = flights[-1]
                start_airport = previous.end_airport
                end_airport = injective_airport(start_airport, truncated_norm(1, nb_airport - 1, (nb_airport - 1) / 2, (nb_airport - 1) / 4))
                minimal_legal_start = previous.end_date + (previous.tat * 60)
                start_date = minimal_legal_start + truncated_norm(min_on_ground, max_on_ground, mean_on_ground, var_on_ground)
                # if we already got a flight starting from A to B, we get back the length of fly and TAT
                if (start_airport, end_airport) in flights_created:
                    if verbose:
                        print("The flight {} - {} has already been added to the database, we retrive the info".format(start_airport, end_airport))
                    previously_created = flights_created[(start_airport, end_airport)]
                    length_fly = previously_created.length_fly
                    tat = previously_created.tat
            # we start the index at 1
            id = len(flights) + 1
            flight_object = models.Flight(id, start_date, length_fly, start_airport, end_airport, aircraft, tat)
            # we add the flight to the first flight assigned to each aircraft if it's the first flight of the aircraft
            if first_flight :
                first_fligth_aircraft[aircraft] = flight_object
            flights.append(flight_object)
            first_flight = False
            if not (start_airport, end_airport) in flights_created:
                flights_created[(start_airport, end_airport)] = flight_object
    solution = models.Solution(nb_aircraft, nb_airport, flights, first_fligth_aircraft)
    return solution

def main():
    parser = argparse.ArgumentParser(description='Generate instance for the routing algorithm')
    parser.add_argument('--aicraft', type=int, help="the number of aircrafts in the outputed instance")
    parser.add_argument('--airport', type=int, help="the number of airports in the outputed instance")
    parser.add_argument('--meanFlightLength', type=int, help="Average length of the flights (in minutes)")
    parser.add_argument('--varFlightLength', type=int, help="Variance of the length of the flights (in minutes)")
    parser.add_argument('--minFlightLength', type=int, help="Minimum length of the flights (in minutes)")
    parser.add_argument('--maxFlightLength', type=int, help="Maximum length of the flights (in minutes)")

    parser.add_argument('--meanFlightAircraft', type=int, help="Average flights per aicraft")
    parser.add_argument('--varFlightAircraft', type=int, help="Variance of flights per aicraft")
    parser.add_argument('--minFlightAircraft', type=int, help="Minimum flights per aicraft")
    parser.add_argument('--maxFlightAircraft', type=int, help="Maximum flights per aicraft")

    parser.add_argument('--meanTat', type=int, help="Average TAT between two flights (in minutes)")
    parser.add_argument('--varTat', type=int, help="Variance TAT between two flights (in minutes)")
    parser.add_argument('--minTat', type=int, help="Minimum TAT between two flights (in minutes)")
    parser.add_argument('--maxTat', type=int, help="Maximum TAT between two flights (in minutes)")

    parser.add_argument('--meanGroundTime', type=int, help="Average time on ground between two flights (in minutes)")
    parser.add_argument('--varGroundTime', type=int, help="Variance time on ground between two flights (in minutes)")
    parser.add_argument('--minGroundTime', type=int, help="Min time on ground between two flights (in minutes)")
    parser.add_argument('--maxGroundTime', type=int, help="Max time on ground between two flights (in minutes)")

    parser.add_argument('--output_file', type=str, help="The name of the output file of the instance")

    parser.add_argument('--default', action='store_true', help="This generate instancies with default value for the previously listed arguments")

    parser.add_argument('--gannt', action='store_true', help="This will output the gannt")

    parser.add_argument('--verbose', action='store_true', help="To get more information while the data are generated")

    args = parser.parse_args()

    output_file = "instance"
    if args.output_file != None:
        output_file =  args.output_file

    # if the user asked for default value
    if args.default:
        solution = instance_generator(verbose = args.verbose)
    else:
        # we ask when we don't have the value specified by the input
        if args.aicraft != None:
            nb_aircraft = args.aicraft
        else:
            nb_aircraft = int(input("Enter the number of aircrafts : "))
        if args.aicraft != None:
            nb_airport = args.aicraft
        else:
            nb_airport = int(input("Enter the number of airports : "))
        # information about length of flights
        if args.meanFlightLength != None and args.varFlightLength != None and args.minFlightLength != None and args.maxFlightLength != None:
            mean_length_flight = args.meanFlightLength
            var_length_flight = args.varFlightLength
            min_length_flight = args.minFlightLength
            max_length_flight = args.maxFlightLength
        else:
            mean_length_flight = int(input("Mean length of the flights (in minutes) : "))
            var_length_flight = int(input("Variance of the length of the flights (still in minutes) : "))
            min_length_flight = int(input("Min length of the flights (still in minutes) : "))
            max_length_flight = int(input("Max length of the flights (still in minutes) : "))
        # information about number of flight to aircraft
        if args.meanFlightAircraft != None and args.varFlightAircraft != None and args.minFlightAircraft != None and args.maxFlightAircraft != None:
            mean_flight_per_aicraft = args.meanFlightAircraft
            var_flight_per_aicraft = args.varFlightAircraft
            min_flight_per_aicraft = args.minFlightAircraft
            max_flight_per_aicraft = args.maxFlightAircraft
        else:
            mean_flight_per_aicraft = int(input("Mean flight per aicraft : "))
            var_flight_per_aicraft = int(input("Variance flight per aicraft : "))
            min_flight_per_aicraft = int(input("Min flight per aicraft : "))
            max_flight_per_aicraft = int(input("Max flight per aicraft : "))
        # information about TAT (Turn Around Time) between two flights
        if args.meanTat != None and args.varTat != None and args.minTat != None and args.maxTat != None:
            mean_tat = args.meanTat
            var_tat = args.varTat
            min_tat = args.minTat
            max_tat = args.maxTat
        else:
            print("TAT (Turn around time) : the minimal legal time between two flights")
            mean_tat = int(input("Mean TAT between two flights : "))
            var_tat = int(input("Variance TAT between two flights : "))
            min_tat = int(input("Min TAT between two flights : "))
            max_tat = int(input("Max TAT between two flights : "))
        # get the maximum time on ground between two flight (after TAT)
        if args.meanGroundTime != None and args.varGroundTime != None and args.minGroundTime != None and args.maxGroundTime != None:
            mean_on_ground = args.meanGroundTime
            var_on_ground = args.varGroundTime
            min_on_ground = args.minGroundTime
            max_on_ground = args.maxGroundTime
        else:
            print("Time on ground : the time after minimal tat between flights")
            mean_on_ground = int(input("Mean time on ground between two flights (in minutes) : "))
            var_on_ground = int(input("Variance time on ground between two flights (in minutes) : "))
            min_on_ground = int(input("Min time on ground between two flights (in minutes) : "))
            max_on_ground = int(input("Max time on ground between two flights (in minutes) : "))
        solution = instance_generator(nb_aircraft,
        nb_airport,
        mean_length_flight,
        var_length_flight,
        min_length_flight,
        max_length_flight,
        mean_flight_per_aicraft,
        var_flight_per_aicraft,
        min_flight_per_aicraft,
        max_flight_per_aicraft,
        mean_tat,
        var_tat,
        min_tat,
        max_tat,
        mean_on_ground,
        var_on_ground,
        min_on_ground,
        max_on_ground,
        args.verbose)

    if args.gannt:
        gannt(solution)
        
    asp_input_fact(output_file, solution)

def gannt(solution):
    data = []
    for flight in solution.flights:
        flight_data = ["Aircraft " + str(flight.assigned_aircraft), datetime.datetime.fromtimestamp(flight.start_date), datetime.datetime.fromtimestamp(flight.end_date), str(flight.start_airport) + " - " + str(flight.end_airport), flight.tat]
        data.append(flight_data)
    df = pd.DataFrame(data, columns=["Task", "Start", "Finish", "Resource", "Complete"])
    colors = [tuple([random.random() for i in range(3)]) for i in range(solution.nb_airport)]
    fig = ff.create_gantt(df,colors=colors, group_tasks=True)
    # we need to create label for displaying the start and end airport
    tmp = []
    for flight in solution.flights:
        tmp.append(dict(x=time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(flight.start_date)), y=solution.nb_aircraft - flight.assigned_aircraft - 1, text=str(flight.start_airport), showarrow=False, font=dict(color='black')))
        tmp.append(dict(x=time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(flight.end_date)), y=solution.nb_aircraft - flight.assigned_aircraft - 1, text=str(flight.end_airport), showarrow=False, font=dict(color='black')))
    fig['layout']['annotations'] = tuple(tmp)
    # we also show the TAT
    for flight in solution.flights:
        fig.add_trace(
            go.Scatter(
                x=[time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(flight.end_date)), time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(flight.end_date + flight.tat * 60))],
                y=[solution.nb_aircraft - flight.assigned_aircraft - 1, solution.nb_aircraft - flight.assigned_aircraft - 1],
                mode="lines",
                line=go.scatter.Line(color="black"),
                showlegend=False)
        )
    fig.show()

def asp_input_fact(output_file, solution):
    # we put the generated instance inside the ../instances folder
    file = open(str(pathlib.Path(__file__).parent.parent) + "/instances/" + output_file + ".lp", "w")
    file.write(repr(solution))


if __name__== "__main__":
      main()