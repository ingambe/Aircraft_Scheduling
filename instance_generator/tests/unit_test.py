#!/usr/bin/env python

import pytest

import sys
sys.path.append("..")
import route_gen
from default_parameters import *

default_solution = route_gen.instance_generator()

def test_nb_ressources():
    assert default_solution.nb_aircraft == default_nb_aircraft, "test failed, number of aicraft different has requested"
    assert default_solution.nb_airport == default_nb_airport, "test failed, number of airports different has requested"


def test_flight_properties():
    flights = default_solution.flights
    for flight in flights:
        assert flight.start_date < flight.end_date, "test failed, end is before start"
        assert flight.start_airport != flight.end_airport, "test failed, airport of start and end are the same"
        assert flight.start_date + flight.length_fly == flight.end_date, "test failed, problem when we have computed the lenght of the flight"
        assert flight.length_fly <= default_max_length_flight, "test failed, we exceed the maximum lenght of flight"
        assert flight.length_fly >= default_min_length_flight, "test failed, we are below the minimum lenght of flight"
        assert flight.tat <= default_max_tat, "test failed, we exceed the maximum lenght of tat"
        assert flight.tat >= default_min_tat, "test failed, we are below the minimum lenght of tat"

def test_coherence_solution():
    ''' Now the interesting part, we are going to ensure that the given solution is coherent, all enonced rules needs to be respected '''
    flight_of_aircrafts = default_solution.flight_of_aircraft
    # for each flight of aircraft
    for flight_of_aircraft in flight_of_aircrafts:
        # we get all the flight
        for i in range(0, len(flight_of_aircraft) - 1):
            current_flight = flight_of_aircraft[i]
            next_flight = flight_of_aircraft[i + 1]
            assert current_flight.start_date < next_flight.start_date, "test failed, previous flight start is after next flight start date"
            assert current_flight.end_date < next_flight.start_date, "test failed, previous flight end is after next flight start date"
            assert current_flight.end_date + current_flight.tat <= next_flight.start_date, "test failed, previous flight end + is TAT is after next flight start date"
            assert current_flight.assigned_aircraft != next_flight.assigned_aircraft, "test failed, assigned aircraft are differents"
            # i + 1 because array index starts at 0, be we start at 1
            assert current_flight.assigned_aircraft != i + 1, "test failed, problem during flight of aircraft storage, aircraft are swapped"
            assert current_flight.end_airport == next_flight.start_airport, "test failed, the end airport of the first is not the same as the start of the second one"
            time_on_ground = next_flight.start_date - (current_flight.end_date + current_flight.tat)
            assert time_on_ground >= default_min_on_ground, "test fail, too little time on ground"
            assert time_on_ground <= default_max_on_ground, "test fail, too much time on ground"
        assert len(flight_of_aircraft) <= default_max_flight_per_aicraft, "test failed, we exceed the maximum limit of flight per aircraft"
        assert len(flight_of_aircraft) >= default_min_flight_per_aicraft, "test failed, we are below the minimum limit of flight per aircraft"