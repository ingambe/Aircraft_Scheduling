import numpy as np
from scipy.stats import truncnorm
import time
import sys
import pandas as pd
import plotly.figure_factory as ff
import datetime

def injective_airport(start, end):
    """ Injective function to map [0, nb\_airport] -> [0, nb\_airport]\start """ 
    if end < start:
        return end
    return end + 1

def truncated_norm(minimum, maximum, mean, sd):
    return truncnorm(a = (minimum - mean) / sd, b = (maximum - mean) / sd, scale=sd, loc=mean).rvs(size=1).round().astype(int)[0]

class Flight(object):
     def __init__(self, start_date, length_fly, start_airport, end_airport, assigned_aircraft, tat):
         self.start_date = start_date
         self.length_fly = length_fly
         self.end_date = start_date + length_fly
         self.start_airport = start_airport
         self.end_airport = end_airport
         self.assigned_aircraft = assigned_aircraft
         self.tat = tat

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
        nb_aircraft = 5
        nb_airport = 30
        mean_length_flight = 5
        var_length_flight = 2
        min_length_flight = 2
        max_length_flight = 10
        mean_flight_per_aicraft = 100
        var_flight_per_aicraft = 10
        min_flight_per_aicraft = 20
        max_flight_per_aicraft = 150
        mean_tat = 45
        var_tat = 10
        min_tat = 30
        max_tat = 60
        mean_on_ground = 30
        var_on_ground = 10
        min_on_ground = 0
        max_on_ground = 60

    # TODO : check the user inputs

    flights = []

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
                first_flight = False
                start_airport = truncated_norm(0, nb_airport, nb_airport / 2, nb_airport / 4)
                end_airport = injective_airport(start_airport, truncated_norm(0, nb_airport - 1, (nb_airport - 1) / 2, (nb_airport - 1) / 4))
                # multiply by 60 to convert from minute to second (epoch is in second)
                # this allow to have a normal distribution between the flight end a time now and the flight start at time now
                start_date = truncated_norm(time_now - length_fly, time_now + length_fly, time_now, time_now / 4)
            else:
                start_airport = injective_airport(start_airport, truncated_norm(0, nb_airport - 1, (nb_airport - 1) / 2, (nb_airport - 1) / 4))
                end_airport = injective_airport(start_airport, truncated_norm(0, nb_airport - 1, (nb_airport - 1) / 2, (nb_airport - 1) / 4))
                # we recover the previous fligth (last added)
                previous = flights[-1]
                minimal_legal_start = previous.end_date + previous.tat
                start_date = minimal_legal_start + truncated_norm(min_on_ground, max_on_ground, mean_on_ground, var_on_ground)
            flight_object = Flight(start_date, length_fly, start_airport, end_airport, aircraft, tat)
            flights.append(flight_object)
    gannt(flights)

def gannt(flights):
    data = []
    for flight in flights:
        flight_data = [flight.assigned_aircraft, datetime.datetime.fromtimestamp(flight.start_date), datetime.datetime.fromtimestamp(flight.end_date), str(flight.start_airport) + " - " + str(flight.end_airport), flight.tat]
        data.append(flight_data)
    df = pd.DataFrame(data, columns=["Task", "Start", "Finish", "Resource", "Complete"])
    print(df)
    fig = ff.create_gantt(df, group_tasks=True)
    fig.show()
    
if __name__== "__main__":
      main(sys.argv[1:])