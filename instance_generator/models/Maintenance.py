from .Flight import Flight


class Maintenance(Flight):
    def __init__(self, id, start_date, length_fly, start_airport, assigned_aircraft):
        self.id = id
        self.start_date = start_date
        self.length_fly = length_fly
        self.end_date = start_date + length_fly
        self.start_airport = start_airport
        self.end_airport = start_airport
        self.assigned_aircraft = assigned_aircraft
        self.tat = 0
