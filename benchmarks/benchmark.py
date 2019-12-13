#!/usr/bin/env python

import os
import argparse
import clyngor
from os.path import isfile, join
import time
import pandas as pd 
from datetime import datetime

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
    parser.add_argument('--all', action='store_true', help="if we need to find all the solutions")
    args = parser.parse_args()
    number_of_run = args.runs
    print("Start of the benchmarks")
    encodings = [x for x in os.listdir("../encoding_benchmark/")]
    print("Encodings to test:")
    for encoding in encodings:
        print("\t-{}".format(encoding))
    results = []
    for i in range(number_of_run):
        print("Iteration {}".format(i))
        result_iteration = dict()
        instance = route_gen.instance_generator()
        for encoding in encodings:
            print("Encoding {}".format(encoding))
            files_encoding = ["../encoding_benchmark/" + encoding + "/" + f for f in os.listdir("../encoding_benchmark/" + encoding) if isfile(join("../encoding_benchmark/" + encoding, f))]
            print("Encodings files {}".format(files_encoding))
            start = time.time()
            if args.all != None:
                answers = clyngor.solve(files=files_encoding, inline=repr(instance))
            else:
                answers = clyngor.solve(files=files_encoding, inline=repr(instance), nb_model=1)
            end = time.time()
            duration = end - start
            correct_solution = True
            for answer in answers:
                asp_str = ' '.join(clyngor.utils.generate_answer_set_as_str(answer, atom_end='.'))
                test_correctness = clyngor.solve(inline=asp_str + repr(instance), files=["../test_solution/test_solution.lp"])
                corrects = [correct for correct in test_correctness]
                if len(corrects) == 0 : 
                    correct_solution = False
                    break
            if correct_solution:
                result_iteration[encoding] = duration
            else:
                result_iteration[encoding] = sys.maxint
        results.append(result_iteration)
    df = pd.DataFrame(results)
    now = datetime.now()
    date_string = now.strftime("%d_%m_%Y_%H_%M_%S")
    df.to_csv("results/" + date_string + ".csv")

if __name__== "__main__":
      main()