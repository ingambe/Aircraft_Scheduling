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
    return truncnorm(a=(minimum - mean) / sd,
                     b=(maximum - mean) / sd,
                     scale=sd,
                     loc=mean).rvs(size=1).round().astype(int)[0]


def instance_generator(nb_aircraft=default_nb_aircraft,
                       nb_airport=default_nb_airport,
                       mean_length_flight=default_mean_length_flight,
                       var_length_flight=default_var_length_flight,
                       min_length_flight=default_min_length_flight,
                       max_length_flight=default_max_length_flight,
                       mean_flight_per_aicraft=default_mean_flight_per_aicraft,
                       var_flight_per_aicraft=default_var_flight_per_aicraft,
                       min_flight_per_aicraft=default_min_flight_per_aicraft,
                       max_flight_per_aicraft=default_max_flight_per_aicraft,
                       mean_tat=default_mean_tat,
                       var_tat=default_var_tat,
                       min_tat=default_min_tat,
                       max_tat=default_max_tat,
                       mean_on_ground=default_mean_on_ground,
                       var_on_ground=default_var_on_ground,
                       min_on_ground=default_min_on_ground,
                       max_on_ground=default_max_on_ground,
                       verbose=False,
                       long=default_force,
                       long_ground_time=default_ground_force,
                       short=default_short,
                       short_violation=default_short_violation,
                       tat_cost=default_tat_cost,
                       nb_airport_maintenance=default_nb_airport_maintenance,
                       length_maintenance=default_length_maintenance):
    ''' This function generate a Solution model '''
    # all the flight and maintenance created and allocated to an aircraft
    flights_and_maintenances = []
    flights = []

    # represent all unique flight created (i.e. starting from airport A to airport B)
    flights_created = dict()

    # represent the first flight of each aircraft in the gant (first before now)
    first_flight_aircraft = [None for i in range(nb_aircraft)]

    time_now = int(time.time())
    flights_per_aircraft = [0 for i in range(nb_aircraft)]

    # here we store the current and start counter of the aircraft maintenance
    second_last_maintenance = {}
    second_initial_counter = {}
    SECONDS_seven_dayS = 10080 * 60
    # we leave at least one day, to avoid having the aircraft already overused
    second_last_maintenance['seven_day'] = [truncated_norm(
        0, SECONDS_seven_dayS - (SECONDS_seven_dayS / 7),
           SECONDS_seven_dayS / 2, SECONDS_seven_dayS / 7) for i in range(nb_aircraft)]
    second_initial_counter['seven_day'] = [count for count in second_last_maintenance['seven_day']]

    # here we store the maintenance limits
    limit_second_last_maintenance = {}
    limit_second_last_maintenance['seven_day'] = SECONDS_seven_dayS

    # here we store the length of the maintenance
    LENGTH_SEC_MAINTENANCE = {}
    LENGTH_SEC_MAINTENANCE["seven_day"] = length_maintenance

    # here we store the airport of the maintenance
    AIRPORTS_MAINTENANCE = {}
    AIRPORTS_MAINTENANCE["seven_day"] = np.random.randint(nb_airport, size=nb_airport_maintenance)

    # we add the special airport to the maintenance compatible list
    # we ensure the long aircraft is not overdue from the beginning
    special_airports = list()
    if long and short:
        special_airports = [nb_airport, nb_airport + 1, nb_airport + 2, nb_airport + 3]
        second_initial_counter['seven_day'][nb_aircraft - 2] = 0
    elif long or short:
        special_airports = [nb_airport, nb_airport + 1]
        if long:
            second_initial_counter['seven_day'][nb_aircraft - 1] = 0
    AIRPORTS_MAINTENANCE["seven_day"] = np.append(AIRPORTS_MAINTENANCE["seven_day"], special_airports)

    upper_bound_solution_cost = 0

    for aircraft in range(nb_aircraft):
        flights_per_aircraft[aircraft] = truncated_norm(
            min_flight_per_aicraft, max_flight_per_aicraft,
            mean_flight_per_aicraft, var_flight_per_aicraft)
        if verbose:
            print("For aircraft {} we have {} flights".format(
                aircraft, flights_per_aircraft[aircraft]))
        first_flight = True
        current_second_last_maintenance = {}
        for maintenance in second_last_maintenance:
            current_second_last_maintenance[maintenance] = second_last_maintenance[maintenance][aircraft]

        if verbose:
            print("For aircraft {} the current counter is {} for a maximum of {}".format(
                aircraft, current_second_last_maintenance['seven_day'], flights_per_aircraft[aircraft]))

        for i in range(flights_per_aircraft[aircraft]):
            # we define a length of the flight, multiply by 60 to convert from minute to second (EPOCH)
            length_fly = truncated_norm(min_length_flight, max_length_flight,
                                        mean_length_flight,
                                        var_length_flight) * 60
            # we compute the tat
            tat = truncated_norm(min_tat, max_tat, mean_tat, var_tat) * 60

            # for the first flight, the start airport is to be chosen between [0, nb_airport]
            # also, as we don't have previous flight, we need to determine a start date
            if first_flight:
                if long and not short and aircraft == nb_aircraft - 1:
                    start_airport = nb_airport
                    end_airport = nb_airport + 1
                    start_date = truncated_norm(time_now - length_fly,
                                                time_now + length_fly,
                                                time_now, time_now / 4)
                elif long and short and aircraft == nb_aircraft - 2:
                    start_airport = nb_airport
                    end_airport = nb_airport + 1
                    start_date = truncated_norm(time_now - length_fly,
                                                time_now + length_fly,
                                                time_now, time_now / 4)
                elif short and not long and aircraft == nb_aircraft - 1:
                    start_airport = nb_airport
                    end_airport = nb_airport + 1
                    start_date = truncated_norm(time_now - length_fly,
                                                time_now + length_fly,
                                                time_now, time_now / 4)

                elif short and long and aircraft == nb_aircraft - 1:
                    start_airport = nb_airport + 2
                    end_airport = nb_airport + 3
                    start_date = truncated_norm(time_now - length_fly,
                                                time_now + length_fly,
                                                time_now, time_now / 4)
                else:

                    start_airport = truncated_norm(1, nb_airport,
                                                   math.ceil(nb_airport / 2),
                                                   math.ceil(nb_airport / 4))
                    end_airport = injective_airport(
                        start_airport,
                        truncated_norm(1, nb_airport - 1,
                                       math.ceil((nb_airport - 1) / 2),
                                       math.ceil((nb_airport - 1) / 4)))
                    if verbose:
                        print("First flight of aircraft {}, is {} - {}".format(
                            i, start_airport, end_airport))
                    # multiply by 60 to convert from minute to second (epoch is in second) this allow to have a
                    # normal distribution between the flight end a time now and the flight start at time now
                    start_date = truncated_norm(time_now - length_fly,
                                                time_now + length_fly,
                                                time_now, time_now / 4)
                # we start the index at 1
                flight_id = len(flights) + 1
                flight_object = models.Flight(flight_id, start_date, length_fly,
                                                  start_airport, end_airport, aircraft,
                                                  tat)
                if not (start_airport, end_airport) in flights_created:
                    flights_created[(start_airport, end_airport)] = flight_object
                first_flight_aircraft[aircraft] = flight_object
                flights.append(flight_object)
                flights_and_maintenances.append(flight_object)
                first_flight = False
            else:
                # we recover the previous flight or maintenance
                previous = flights_and_maintenances[-1]
                start_airport = previous.end_airport
                #usage_aircraft = 0
                # first we add maintenance if needed
                usage_aircraft = current_second_last_maintenance["seven_day"] / limit_second_last_maintenance['seven_day']
                #print("usage aircraft {}".format(usage_aircraft))
                # we start putting maintenance after 70% usage
                # but anyway if usage reach 90%, we put it
                assert usage_aircraft <= 1.0
                probability_add_maintenance = usage_aircraft + (random.random() * 0.5)
                if long:
                    if short and aircraft == nb_aircraft - 2:
                        probability_add_maintenance = usage_aircraft > 0.5
                    elif aircraft == nb_aircraft - 1:
                        probability_add_maintenance = usage_aircraft > 0.5
                if usage_aircraft > 0.5 and probability_add_maintenance >= 1.0 or usage_aircraft > 0.9:
                    # we get an airport to perform the maintenance and we modify the end airport of the previous
                    # flight we need to ensure that the start and end airport of the previous start doesn't end
                    # up being the same
                    if previous.end_airport not in AIRPORTS_MAINTENANCE["seven_day"]:
                        all_airports_except_start = [x for x in AIRPORTS_MAINTENANCE["seven_day"] if
                                                     x != previous.start_airport]
                        airport_maintenance = random.choice(all_airports_except_start)
                        previous_flight = flights[-1]
                        previous_flight.end_airport = airport_maintenance
                        previous.end_airport = airport_maintenance
                    flight_id = len(flights) + 1
                    length_maintenance = LENGTH_SEC_MAINTENANCE["seven_day"]
                    maintenance = models.Maintenance(flight_id, previous.end_date, length_maintenance,
                                                     airport_maintenance, aircraft)
                    flights_and_maintenances.append(maintenance)
                    current_second_last_maintenance["seven_day"] = 0
                    # we don't count the maintenance in the flights counter
                    i -= 1
                    upper_bound_solution_cost += 101
                else:
                    if long and not short and aircraft == nb_aircraft - 1:
                        if start_airport == nb_airport:
                            end_airport = nb_airport + 1
                        else:
                            end_airport = nb_airport
                        minimal_legal_start = previous.end_date + previous.tat
                        start_date = minimal_legal_start + long_ground_time * 60
                    elif long and short and aircraft == nb_aircraft - 2:
                        if start_airport == nb_airport:
                            end_airport = nb_airport + 1
                        else:
                            end_airport = nb_airport
                        minimal_legal_start = previous.end_date + previous.tat
                        start_date = minimal_legal_start + long_ground_time * 60
                    elif short and not long and aircraft == nb_aircraft - 1:
                        if start_airport == nb_airport:
                            end_airport = nb_airport + 1
                        else:
                            end_airport = nb_airport
                        minimal_legal_start = previous.end_date + previous.tat
                        start_date = minimal_legal_start - short_violation * 60
                        upper_bound_solution_cost += tat_cost
                    elif short and long and aircraft == nb_aircraft - 1:
                        if start_airport == nb_airport + 2:
                            end_airport = nb_airport + 3
                        else:
                            end_airport = nb_airport + 2
                        minimal_legal_start = previous.end_date + previous.tat
                        start_date = minimal_legal_start - short_violation * 60
                        upper_bound_solution_cost += tat_cost
                    else:
                        end_airport = injective_airport(
                            start_airport,
                            truncated_norm(1, nb_airport - 1, (nb_airport - 1) / 2,
                                           (nb_airport - 1) / 4))
                        minimal_legal_start = previous.end_date + previous.tat
                        on_ground_time = truncated_norm(
                            min_on_ground, max_on_ground, mean_on_ground,
                            var_on_ground) * 60
                        start_date = minimal_legal_start + on_ground_time
                    # if we already got a flight starting from A to B, we get back the length of fly and TAT
                    if (start_airport, end_airport) in flights_created:
                        if verbose:
                            print(
                                "The flight {} - {} has already been added to the database, we "
                                "retrieve the info".format(start_airport, end_airport))
                        previously_created = flights_created[(start_airport,
                                                              end_airport)]
                        length_fly = previously_created.length_fly
                        tat = previously_created.tat

                    # we start the index at 1
                    flight_id = len(flights) + 1
                    flight_object = models.Flight(flight_id, start_date, length_fly,
                                                  start_airport, end_airport, aircraft,
                                                  tat)
                    # we update maintenance counter
                    for maintenance in current_second_last_maintenance:
                        time_elapsed = flight_object.end_date - previous.end_date
                        current_second_last_maintenance[maintenance] += time_elapsed
                    if not (start_airport, end_airport) in flights_created:
                        flights_created[(start_airport, end_airport)] = flight_object
                    flights.append(flight_object)
                    flights_and_maintenances.append(flight_object)

    solution = models.Solution(nb_aircraft, nb_airport, flights, first_flight_aircraft
                               , flights_created, second_initial_counter, limit_second_last_maintenance, LENGTH_SEC_MAINTENANCE, AIRPORTS_MAINTENANCE)

    if long:
        # we have added two airports for the two special long airport
        nb_airport += 2
    if short:
        # we have added two airports for the two special short tat airport
        nb_airport += 2
    return solution, upper_bound_solution_cost


def main():
    parser = argparse.ArgumentParser(
        description='Generate instance for the routing algorithm')
    parser.add_argument(
        '--aircraft',
        type=int,
        help="the number of aircraft in the outputted instance")
    parser.add_argument('--airport',
                        type=int,
                        help="the number of airports in the outputted instance")
    parser.add_argument('--meanFlightLength',
                        type=int,
                        help="Average length of the flights (in minutes)")
    parser.add_argument(
        '--varFlightLength',
        type=int,
        help="Variance of the length of the flights (in minutes)")
    parser.add_argument('--minFlightLength',
                        type=int,
                        help="Minimum length of the flights (in minutes)")
    parser.add_argument('--maxFlightLength',
                        type=int,
                        help="Maximum length of the flights (in minutes)")

    parser.add_argument('--meanFlightAircraft',
                        type=int,
                        help="Average flights per aircraft")
    parser.add_argument('--varFlightAircraft',
                        type=int,
                        help="Variance of flights per aircraft")
    parser.add_argument('--minFlightAircraft',
                        type=int,
                        help="Minimum flights per aircraft")
    parser.add_argument('--maxFlightAircraft',
                        type=int,
                        help="Maximum flights per aircraft")

    parser.add_argument('--meanTat',
                        type=int,
                        help="Average TAT between two flights (in minutes)")
    parser.add_argument('--varTat',
                        type=int,
                        help="Variance TAT between two flights (in minutes)")
    parser.add_argument('--minTat',
                        type=int,
                        help="Minimum TAT between two flights (in minutes)")
    parser.add_argument('--maxTat',
                        type=int,
                        help="Maximum TAT between two flights (in minutes)")

    parser.add_argument(
        '--meanGroundTime',
        type=int,
        help="Average time on ground between two flights (in minutes)")
    parser.add_argument(
        '--varGroundTime',
        type=int,
        help="Variance time on ground between two flights (in minutes)")
    parser.add_argument(
        '--minGroundTime',
        type=int,
        help="Min time on ground between two flights (in minutes)")
    parser.add_argument(
        '--maxGroundTime',
        type=int,
        help="Max time on ground between two flights (in minutes)")

    parser.add_argument('--output_file',
                        type=str,
                        help="The name of the output file of the instance")

    parser.add_argument(
        '--default',
        action='store_true',
        help="This generate instances with default value for the previously listed arguments"
    )

    parser.add_argument('--gannt',
                        action='store_true',
                        help="This will output the gannt")

    parser.add_argument(
        '--verbose',
        action='store_true',
        help="To get more information while the data are generated")

    parser.add_argument(
        '--force_long',
        action='store_true',
        help="Force to have a long ground time flight by having two specific aircraft"
    )
    parser.add_argument('--long_minutes_ground_time',
                        type=int,
                        help="Minutes of ground time between the long flight")

    args = parser.parse_args()

    output_file = "instance"
    if args.output_file is not None:
        output_file = args.output_file

    # if the user asked for default value
    if args.default:
        solution, _ = instance_generator(verbose=args.verbose)
    else:
        # we ask when we don't have the value specified by the input
        if args.aircraft is not None:
            nb_aircraft = args.aircraft
        else:
            nb_aircraft = int(input("Enter the number of aircrafts : "))
        if args.airport is not None:
            nb_airport = args.airport
        else:
            nb_airport = int(input("Enter the number of airports : "))
        # information about length of flights
        if args.meanFlightLength is not None \
                and args.varFlightLength is not None \
                and args.minFlightLength is not None \
                and args.maxFlightLength is not None:
            mean_length_flight = args.meanFlightLength
            var_length_flight = args.varFlightLength
            min_length_flight = args.minFlightLength
            max_length_flight = args.maxFlightLength
        else:
            mean_length_flight = int(
                input("Mean length of the flights (in minutes) : "))
            var_length_flight = int(
                input(
                    "Variance of the length of the flights (still in minutes) : "
                ))
            min_length_flight = int(
                input("Min length of the flights (still in minutes) : "))
            max_length_flight = int(
                input("Max length of the flights (still in minutes) : "))
        # information about number of flight to aircraft
        if args.meanFlightAircraft is not None and args.varFlightAircraft is not None and \
                args.minFlightAircraft is not None and args.maxFlightAircraft is not None:
            mean_flight_per_aircraft = args.meanFlightAircraft
            var_flight_per_aircraft = args.varFlightAircraft
            min_flight_per_aircraft = args.minFlightAircraft
            max_flight_per_aircraft = args.maxFlightAircraft
        else:
            mean_flight_per_aircraft = int(input("Mean flight per aircraft : "))
            var_flight_per_aircraft = int(
                input("Variance flight per aircraft : "))
            min_flight_per_aircraft = int(input("Min flight per aircraft : "))
            max_flight_per_aircraft = int(input("Max flight per aircraft : "))
        # information about TAT (Turn Around Time) between two flights
        if args.meanTat is not None and \
                args.varTat is not None and \
                args.minTat is not None and \
                args.maxTat is not None:
            mean_tat = args.meanTat
            var_tat = args.varTat
            min_tat = args.minTat
            max_tat = args.maxTat
        else:
            print(
                "TAT (Turn around time) : the minimal legal time between two flights"
            )
            mean_tat = int(input("Mean TAT between two flights : "))
            var_tat = int(input("Variance TAT between two flights : "))
            min_tat = int(input("Min TAT between two flights : "))
            max_tat = int(input("Max TAT between two flights : "))
        # get the maximum time on ground between two flight (after TAT)
        if args.meanGroundTime is not None and \
                args.varGroundTime is not None and \
                args.minGroundTime is not None and \
                args.maxGroundTime is not None:
            mean_on_ground = args.meanGroundTime
            var_on_ground = args.varGroundTime
            min_on_ground = args.minGroundTime
            max_on_ground = args.maxGroundTime
        else:
            print(
                "Time on ground : the time after minimal tat between flights")
            mean_on_ground = int(
                input(
                    "Mean time on ground between two flights (in minutes) : "))
            var_on_ground = int(
                input(
                    "Variance time on ground between two flights (in minutes) : "
                ))
            min_on_ground = int(
                input(
                    "Min time on ground between two flights (in minutes) : "))
            max_on_ground = int(
                input(
                    "Max time on ground between two flights (in minutes) : "))
        solution, _ = instance_generator(
            nb_aircraft, nb_airport, mean_length_flight, var_length_flight,
            min_length_flight, max_length_flight, mean_flight_per_aircraft,
            var_flight_per_aircraft, min_flight_per_aircraft,
            max_flight_per_aircraft, mean_tat, var_tat, min_tat, max_tat,
            mean_on_ground, var_on_ground, min_on_ground, max_on_ground,
            args.verbose, args.force_long, args.long_minutes_ground_time)

    if args.gannt:
        gannt(solution)

    asp_input_fact(output_file, solution)


def gannt(solution):
    assigned_air = [0 for i in range(solution.nb_aircraft)]
    df = []
    maintenance_in_solution = False

    unique_flight = dict()
    for flight in solution.flights:
        dict_flight = dict()
        dict_flight["Task"] = "Aircraft " + str(flight.assigned_aircraft)
        assigned_air[flight.assigned_aircraft] += 1
        dict_flight["Start"] = datetime.datetime.fromtimestamp(flight.start_date)
        dict_flight["Finish"] = datetime.datetime.fromtimestamp(flight.end_date)
        if isinstance(flight, models.Maintenance) or flight.start_airport == flight.end_airport:
            dict_flight["Resource"] = "Maintenance"
            maintenance_in_solution = True
        else:
            dict_flight["Resource"] = str(flight.start_airport) + " - " + str(flight.end_airport)
            unique_flight[str(flight.start_airport) + " - " + str(flight.end_airport)] = 1
        dict_flight["Complete"] = flight.tat
        df.append(dict_flight)

    # we create a color for each flight + 1 for the maintenance
    colors = [
        tuple([random.random() for i in range(3)]) for i in range(len(unique_flight) + int(maintenance_in_solution))
    ]
    fig = ff.create_gantt(df, colors=colors, index_col='Resource', group_tasks=True)
    # we need to create label for displaying the start and end airport
    tmp = []
    for flight in solution.flights:
        tmp.append(
            dict(x=time.strftime('%Y-%m-%d %H:%M:%S',
                                 time.localtime(flight.start_date)),
                 y=solution.nb_aircraft - flight.assigned_aircraft - 1,
                 text=str(flight.start_airport),
                 showarrow=False,
                 font=dict(color='black')))
        tmp.append(
            dict(x=time.strftime('%Y-%m-%d %H:%M:%S',
                                 time.localtime(flight.end_date)),
                 y=solution.nb_aircraft - flight.assigned_aircraft - 1,
                 text=str(flight.end_airport),
                 showarrow=False,
                 font=dict(color='black')))
    fig['layout']['annotations'] = tuple(tmp)
    # we also show the TAT
    for flight in solution.flights:
        fig.add_trace(
            go.Scatter(x=[
                time.strftime('%Y-%m-%d %H:%M:%S',
                              time.localtime(flight.end_date)),
                time.strftime(
                    '%Y-%m-%d %H:%M:%S',
                    time.localtime(flight.end_date + flight.tat))
            ],
                y=[
                    solution.nb_aircraft - flight.assigned_aircraft - 1,
                    solution.nb_aircraft - flight.assigned_aircraft - 1
                ],
                mode="lines",
                line=go.scatter.Line(color="black"),
                showlegend=False))
    fig.show()


def asp_input_fact(output_file, solution):
    # we put the generated instance inside the ../instances folder
    file = open(
        str(pathlib.Path(__file__).parent.parent) + "/instances/" +
        output_file + ".lp", "w+")
    file.write(repr(solution))
    file.close()


if __name__ == "__main__":
    main()