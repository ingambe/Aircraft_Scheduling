#!/usr/bin/env python

import pytest

import sys
sys.path.append("..")
import route_gen
from default_parameters import *

default_solution, upper_bound = route_gen.instance_generator()

def test_nb_ressources():
    assert default_solution.nb_aircraft == default_nb_aircraft, "test failed, number of aircraft different has requested"
    assert default_solution.nb_airport == default_nb_airport, "test failed, number of airports different has requested"

def test_flight_properties():
    flights = default_solution.flights
    for flight in flights:
        assert flight.start_date < flight.end_date, "test failed, end is before start"
        assert flight.start_airport != flight.end_airport, "test failed, airport of start and end are the same"
        assert flight.start_date + flight.length_fly == flight.end_date, "test failed, problem when we have computed the lenght of the flight"
        assert flight.length_fly <= default_max_length_flight * 60, "test failed, we exceed the maximum lenght of flight"
        assert flight.length_fly >= default_min_length_flight * 60, "test failed, we are below the minimum lenght of flight"
        assert flight.tat <= default_max_tat * 60, "test failed, we exceed the maximum lenght of tat"
        assert flight.tat >= default_min_tat * 60, "test failed, we are below the minimum lenght of tat"

def test_coherence_solution():
    '''
    Now the interesting part, we are going to ensure that the given solution is coherent, all enonced rules needs to be respected
    We multiply by 60 because default times are given in minutes and time in the instance are in seconds
    '''
    flight_of_aircrafts = default_solution.flight_of_aircraft
    # unique airport and unique aircraft
    unique_airport = set()
    unique_aircraft = set()
    # for each flight of aircraft
    for aircraft in range(len(flight_of_aircrafts)):
        nb_flight_to_aircraft = 0
        flight_of_aircraft = flight_of_aircrafts[aircraft]
        # we get the start counter
        counter = default_solution.start_counters["seven_day"][aircraft]
        limite = default_solution.max_counters["seven_day"] * 60
        # we get all the flight expect the last one
        for i in range(0, len(flight_of_aircraft) - 1):
            assert counter <= limite, "test failed, maintenance counter overdue"
            current_flight = flight_of_aircraft[i]
            next_flight = flight_of_aircraft[i + 1]
            # airports
            unique_airport.add(current_flight.start_airport)
            unique_airport.add(current_flight.end_airport)
            unique_airport.add(next_flight.start_airport)
            unique_airport.add(next_flight.end_airport)
            # airports
            unique_aircraft.add(current_flight.assigned_aircraft)
            unique_aircraft.add(next_flight.assigned_aircraft)
            if current_flight.start_airport == current_flight.end_airport:
                counter = 0
            else:
                nb_flight_to_aircraft += 1
                assert current_flight.start_date < next_flight.start_date, "test failed, previous flight start is after next flight start date"
                assert current_flight.end_date < next_flight.start_date, "test failed, previous flight end is after next flight start date"
                assert current_flight.end_date + current_flight.tat <= next_flight.start_date, "test failed, previous flight end + is TAT is after next flight start date"
                assert current_flight.assigned_aircraft == next_flight.assigned_aircraft, "test failed, assigned aircraft are differents"
                assert current_flight.assigned_aircraft == aircraft, "test failed, problem during flight of aircraft storage, aircraft are swapped"
                time_on_ground = next_flight.start_date - (current_flight.end_date + current_flight.tat)
                assert time_on_ground >= default_min_on_ground * 60, "test fail, too little time on ground"
                assert time_on_ground <= default_max_on_ground * 60, "test fail, too much time on ground"
                counter += (next_flight.start_date - current_flight.end_date)
        assert nb_flight_to_aircraft <= default_max_flight_per_aicraft, "test failed, we exceed the maximum limit of flight per aircraft"
        assert nb_flight_to_aircraft >= default_min_flight_per_aicraft, "test failed, we are below the minimum limit of flight per aircraft"
    assert len(unique_airport) <= default_nb_airport, "test failed, we have more airport than needed"
    assert len(unique_aircraft) == default_nb_aircraft, "test failed, we have less aircraft than needed"
