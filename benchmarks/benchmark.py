#!/usr/bin/env python

from asyncore import read
import os
import argparse
import subprocess
import json
from os.path import isfile, join, basename
import time
from unittest import result
import pandas as pd 
from datetime import datetime
import tempfile
import shutil

import sys
sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), os.path.pardir, 'instance_generator')))
import route_gen

def main():
    '''
    The algorithm for benchmark works as follow:
        For a certain number of iteration:
            generate instance with default generator value
            for each encoding inside subfolders of encoding (one folder for each encoding):
                start timer
                solve with clyngo
                stop timer
                test solution:
                    if legal
                        add time in a csv (S)
                    else:
                        add int max as time
                        print an error message
    '''
    parser = argparse.ArgumentParser(description='Benchmark ! :D')
    parser.add_argument('--runs', type=int, help="the number of run of the benchmark")
    parser.add_argument('--no_check', default=True, action='store_true', help="if we don't want to check the solution (in case of optimization problem)")
    parser.add_argument('--my_inst', action='store_true', help='Add this argument if you want to use already defined instances')
    parser.add_argument('--save_inst', action='store_true', help='Add this argument if you want to save the randomly generated instances')
    parser.add_argument('--winner', action='store_true', help='Add this argument if you want to know the winning core in parallel solving')
    args = parser.parse_args()

    if args.runs and args.my_inst:
        print("Arguments 'runs' and 'my_inst' cannot be used together. Either choose to solve new randomly generated instances or already existing ones.")
        return

    number_of_run = args.runs
    print("Start of the benchmarks")
    encodings = [x for x in os.listdir("../encoding/")]
    print("Encodings to test:")
    for encoding in encodings:
        print("\t-{}".format(encoding))
    results = []
    costs_run = []

    instances = []
    dir_prefix = ""

    # If the program should reuse already created instances.
    if args.my_inst:
        dir_prefix = "./instances/"
        instances = [inst for inst in os.listdir("./instances") if inst.endswith(".lp")]
        number_of_run = len(instances)

    for i in range(number_of_run):
        print("Iteration {}".format(i + 1))
        result_iteration = dict()
        cost_iteration = dict()

        # Load an instance from the ones found in ./instances/
        if args.my_inst:
            inst_lp = instances[i]
            inst_name = inst_lp.strip(".lp")
            
            # Find its benchmark_cost in the .txt file
            cost_file = open(dir_prefix + inst_name + ".txt", 'r')
            minimal_cost = int(cost_file.read().strip('\n'))
            cost_file.close()
            instance_temp = open(dir_prefix + inst_lp, 'r')
        
        # Otherwise generate a random instance.
        else:
            instance, minimal_cost = route_gen.instance_generator()
            instance_temp = tempfile.NamedTemporaryFile(mode="w+", suffix='.lp', dir=".", delete=False)
            instance_temp.write(repr(instance))
            instance_temp.flush()

            # If the instance is to be saved, create a .txt file with the same name containing its benchmark_cost.
            if args.save_inst:
                name_inst = basename(instance_temp.name).strip(".lp")
                cost_file = open("./instances/" + name_inst + ".txt", "w")
                cost_file.write(str(minimal_cost))
                cost_file.close()
                # The instance is saved by copying the temporary file inside ./instances/
                shutil.copy(instance_temp.name, "./instances/")
                

        result_iteration["Instance"] = basename(instance_temp.name)
        cost_iteration["Instance"] = basename(instance_temp.name)

        # we get the upper bound of the solution generated by the generator
        cost_iteration["Benchmark_Cost"] = minimal_cost
        correct_solution = True
        inst_name = basename(instance_temp.name).strip(".lp")
        for encoding in encodings:
            print("Encoding {} (Iteration {}):".format(encoding, i + 1))
            files_encoding = ["../encoding/" + encoding + "/" + f for f in os.listdir("../encoding/" + encoding) if isfile(join("../encoding/" + encoding, f))]
            start = time.time()
            try:
                if encoding.startswith('parallel'):
                    clingo = subprocess.Popen(["clingo"] + files_encoding + [dir_prefix + basename(instance_temp.name)] + ["-c instance=" + inst_name] + ["--outf=2"] + ['-t 8compete'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                else:
                    clingo = subprocess.Popen(["clingo"] + files_encoding + [dir_prefix + basename(instance_temp.name)] + ["-c instance=" + inst_name] + ["--outf=2"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                (stdoutdata, stderrdata) = clingo.communicate(timeout=3660)
                clingo.wait()
                end = time.time()
                duration = end - start
                json_answers = json.loads(stdoutdata)

                cost = float('inf')
                answer = []
                # we need to check all solution and get the best one
                for call_current in json_answers["Call"]:
                    if "Witnesses" in call_current:
                        answer_current = call_current["Witnesses"][-1]
                        if "Costs" in answer_current:
                            current_cost = sum(answer_current["Costs"])
                            if current_cost < cost:
                                answer = answer_current["Value"]
                                cost = current_cost
                        else:
                            cost = 0
                            answer = answer_current["Value"]
                # we append "" just to get the last . when we join latter
                answer = answer + [""]
                answer_str = ".".join(answer)
                answer_temp = tempfile.NamedTemporaryFile(mode="w+", suffix='.lp', dir=".", delete=False)
                answer_temp.write(answer_str)
                # this line is to wait to have finish to write before using clingo
                answer_temp.flush()
                clingo_check = subprocess.Popen(
                    ["clingo"] + ["../test_solution/test_solution.lp"] + [basename(answer_temp.name)] + [
                        dir_prefix + basename(instance_temp.name)] + ["--outf=2"] + ["-q"], stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE)
                (stdoutdata_check, stderrdata_check) = clingo_check.communicate()
                clingo_check.wait()
                json_check = json.loads(stdoutdata_check)
                answer_temp.close()
                os.remove(answer_temp.name)
                if not json_check["Result"] == "SATISFIABLE":
                    correct_solution = False
                if correct_solution:
                    result_iteration[encoding] = duration
                    if args.winner and encoding.startswith('parallel'):
                        cost = str(cost) + " (Winner: " + str(json_answers["Winner"]) + ")"
                    cost_iteration[encoding] = cost
                else:
                    result_iteration[encoding] = sys.maxsize
                    cost_iteration[encoding] = float("inf")
                print("\tInstance name: {}".format(basename(instance_temp.name)))
                print("\tSatisfiable {}".format(correct_solution))
                print("\tDuration {} seconds".format(result_iteration[encoding]))
                print("\tBest solution {}".format(cost))
                print("\tBenchmark cost {}".format(minimal_cost))
            except Exception as excep:
                # Check if a non-optimal solution was found in results/encoding/*.csv
                try:
                    # Wait to make sure the .csv file is saved correctly.
                    print("Timeout reached. Let us see if there is at least a non-optimal solution.")
                    time.sleep(5)  
                    df_ex = pd.read_csv("./results/" + encoding + "/time_" + inst_name + ".csv")
                    
                    # Extract time and cost of the best non-optimal solution (last row).
                    result_iteration[encoding] = str(df_ex.iloc[-1]["Time"]) + "*"
                    cost_iteration[encoding] = str(df_ex.iloc[-1]["Cost"]) + "*"
                    print("\tInstance name: {}".format(basename(instance_temp.name)))
                    print("\tSatisfiable True")
                    print("\tDuration {} seconds (non-optimal)".format(result_iteration[encoding]))
                    print("\tBest solution {} (non-optimal)".format(cost_iteration[encoding]))
                    print("\tBenchmark cost {}".format(minimal_cost))
                
                # Otherwise just set that no solution was found
                except Exception as new_excep:
                    print(new_excep)
                    result_iteration[encoding] = "No solution"
                    cost_iteration[encoding] = float('inf')
        results.append(result_iteration)
        costs_run.append(cost_iteration)
        instance_temp.close()

        # No need to delete the temporary file if already stored instances are being used.
        if not args.my_inst:
            os.remove(basename(instance_temp.name))
    
    df = pd.DataFrame(results)
    now = datetime.now()
    date_string = now.strftime("%d_%m_%Y_%H_%M_%S")
    df.to_csv("results/" + date_string + ".csv")
    # we also print the cost
    df = pd.DataFrame(costs_run)
    df.to_csv("results/" + date_string + "_costs.csv")
    print("Finished!")


if __name__== "__main__":
      main()
