import numpy as np
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

def injective_airport(start, end):
    """ Injective function to map [0, nb_airport] -> [0, nb_airport]\start """ 
    if end < start:
        return end
    return end + 1

def truncated_norm(minimum, maximum, mean, sd):
    return truncnorm(a = (minimum - mean) / sd, b = (maximum - mean) / sd, scale=sd, loc=mean).rvs(size=1).round().astype(int)[0]

def main(argv):
    print("This is used to generate data for the route algorithm")
    if len(argv) == 0 :
        nb_aircraft = int(input("Enter the number of aircrafts : "))
        nb_airport = int(input("Enter the number of airports : "))
        # information about length of flights
        mean_length_flight = int(input("Mean length of the flights (in minutes) : "))
        var_length_flight = int(input("Variance of the length of the flights (still in minutes) : "))
        min_length_flight = int(input("Min length of the flights (still in minutes) : "))
        max_length_flight = int(input("Max length of the flights (still in minutes) : "))
        # information about number of flight to aircraft
        mean_flight_per_aicraft = int(input("Mean flight per aicraft : "))
        var_flight_per_aicraft = int(input("Variance flight per aicraft : "))
        min_flight_per_aicraft = int(input("Min flight per aicraft : "))
        max_flight_per_aicraft = int(input("Max flight per aicraft : "))
        # information about TAT (Turn Around Time) between two flights
        print("TAT (Turn around time) : the minimal legal time between two flights")
        mean_tat = int(input("Mean TAT between two flights : "))
        var_tat = int(input("Variance TAT between two flights : "))
        min_tat = int(input("Min TAT between two flights : "))
        max_tat = int(input("Max TAT between two flights : "))
        # get the maximum time on ground between two flight (after TAT)
        print("Time on ground : the time after minimal tat between flights")
        mean_on_ground = int(input("Mean time on ground between two flights (in minutes) : "))
        var_on_ground = int(input("Variance time on ground between two flights (in minutes) : "))
        min_on_ground = int(input("Min time on ground between two flights (in minutes) : "))
        max_on_ground = int(input("Max time on ground between two flights (in minutes) : "))
    else :
        nb_aircraft = 2
        nb_airport = 3
        mean_length_flight = 80
        var_length_flight = 15
        min_length_flight = 30
        max_length_flight = 150
        mean_flight_per_aicraft = 3
        var_flight_per_aicraft = 1
        min_flight_per_aicraft = 2
        max_flight_per_aicraft = 4
        mean_tat = 45
        var_tat = 10
        min_tat = 30
        max_tat = 60
        mean_on_ground = 3000
        var_on_ground = 1000
        min_on_ground = 0
        max_on_ground = 6000

    # TODO : check the user inputs

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
    gannt(solution)
    asp_input_fact("test.lp", solution)

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
    file = open(output_file, "w")
    print(repr(solution))
    file.write(repr(solution))


if __name__== "__main__":
      main(sys.argv[1:])