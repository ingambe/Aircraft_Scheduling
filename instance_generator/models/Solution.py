class Solution(object):
    def __init__(self, nb_aircraft, nb_airport, fligths, first_fligth_aircraft,
                 unique_flights, start_counters, max_counters, length_maintenance, airport_maintenance):
        self.nb_aircraft = nb_aircraft
        self.nb_airport = nb_airport
        self.flights = fligths
        self.first_fligth_aircraft = first_fligth_aircraft
        self.unique_flights = unique_flights
        # this contains all flight assigned to each aircraft, thus it will be easier to generate a readable solution
        self.flight_of_aircraft = [[] for i in range(self.nb_aircraft)]
        for flight in self.flights:
            self.flight_of_aircraft[flight.assigned_aircraft].append(flight)
        self.start_counters = start_counters
        self.max_counters = max_counters
        self.length_maintenance = length_maintenance
        self.airport_maintenance = airport_maintenance

    def __repr__(self):
        result = ""
        for maintenance_type in self.start_counters:
            result += "maintenance({}).\n".format(maintenance_type)
            result += "length_maintenance({}, {}).\n".format(maintenance_type, self.length_maintenance[maintenance_type])
            for airport in self.airport_maintenance[maintenance_type]:
                result += "airport_maintenance({}, {}).\n".format(maintenance_type, airport + 1)
            for aircraft in range(self.nb_aircraft):
                result += "start_maintenance_counter({}, {}, {}).\n".format(maintenance_type, aircraft + 1,
                                                                            self.start_counters[maintenance_type][aircraft])
        for maintenance_type in self.max_counters:
            result += "limit_counter({}, {}).\n".format(maintenance_type, self.max_counters[maintenance_type])
        result += "aircraft(1..{}).\n".format(self.nb_aircraft)
        result += "airport(1..{}).\n".format(self.nb_airport)
        result += "flight(1..{}).\n".format(len(self.flights))
        # we now print for each aircraft is first flight
        for aircraft in range(len(self.first_fligth_aircraft)):
            flight = self.first_fligth_aircraft[aircraft]
            # +1 because we count aircraft starting from 1 and not 0
            result += "first({}, {}). ".format(flight.id, aircraft + 1)
        result += "\n"
        # we add the airport of departure
        for flight in self.flights:
            result += "airport_start({}, {}). ".format(flight.id, flight.start_airport + 1)
        result += "\n"
        # we add the airport of destination
        for flight in self.flights:
            result += "airport_end({}, {}). ".format(flight.id, flight.end_airport + 1)
        result += "\n"
        # we add the start date of the flight
        for flight in self.flights:
            result += "start({}, {}). ".format(flight.id, flight.start_date)
        result += "\n"
        # we add the end date of the flight
        for flight in self.flights:
            result += "end({}, {}). ".format(flight.id, flight.end_date)
        result += "\n"
        # we add the tat for each flight
        for flight in self.flights:
            result += "tat({}, {}). ".format(flight.id, flight.tat)
        result += "\n"
        # now we will add the solution as a comment
        result += "\n"
        # way more conveniant to check if we get one line per aircraft
        result += "%* One possible solution: \n"
        for aircraft in range(len(self.flight_of_aircraft)):
            result += "For aircraft {}\n".format(aircraft + 1)
            for flight in self.flight_of_aircraft[aircraft]:
                result += "assign({}, {}). ".format(flight.id, aircraft + 1)
            result += "\n\n"
        result += "*%\n"
        return result
