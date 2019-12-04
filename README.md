# Aircraft Scheduling

This is a Proof of Concept for an ASP formulation of the Aircraft Scheduling problem.

## Getting Started
---------------

These instructions will get you a copy of the project up and running on
your local machine for development and testing purposes. See deployment
for notes on how to deploy the project on a live system.

### Prerequisites
~~~~~~~~~~~~~

Which things you need to install the software and how to install them


* [Python3](https://www.python.org/downloads/)
* [Pip](https://pip.pypa.io/en/stable/installing/) Already included in the latest python versions

### Installing
~~~~~~~~~~

First, you need to clone this repository

```bash
git clone https://github.com/ingambe/Aircraft_Scheduling.git
cd Aircraft_Scheduling
```

Optional (but recommanded):
You can create a virtual environement in order to keep the dependencies separated from your own python environement

```bash
pip install virtualenv
virtualenv venv
source venv/Scripts/activate
```

And finally install all the dependencies

```bash
pip install -r requirements.txt
```

## Generate instances
-----------------

The script file [route_gen.py](https://github.com/ingambe/Aircraft_Scheduling/blob/master/instance_generator/route_gen.py) allows you to generate instances.
If you run it without any arguments, it will use the [default one](https://github.com/ingambe/Aircraft_Scheduling/blob/master/instance_generator/default_parameters.py).
The `--gannt` argument generate and display a gannt of the instances:
![example of generated gannt](gannt.png)

## Running the tests
-----------------

TODO

Authors
-------

-  **Pierre Tassel**
-  **Martin Gebser**

License
-------

MIT License
