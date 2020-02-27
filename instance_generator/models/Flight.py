class Flight(object):
    def __init__(self, flight_id, start_date, length_fly, start_airport, end_airport, assigned_aircraft, tat):
        self.id = flight_id
        self.start_date = start_date
        self.length_fly = length_fly
        self.end_date = start_date + length_fly
        self.start_airport = start_airport
        self.end_airport = end_airport
        self.assigned_aircraft = assigned_aircraft
        self.tat = tat
