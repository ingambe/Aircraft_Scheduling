import matplotlib
import matplotlib.pyplot as plt
import os
import pandas as pd
import numpy as np
import seaborn as sns
import sys

encodings = [encoding for encoding in os.listdir(".") if os.path.isdir(encoding)]
color_encoding = dict()
colors = matplotlib.cm.rainbow(np.linspace(0, 1, len(encodings)))

for i, encoding in enumerate(encodings):
    color_encoding[encoding] = colors[i]

for i in range(20):
    for encoding in encodings:
        x = []
        y = []
        dirFiles = os.listdir("{}/".format(encoding))
        # we remove hidden file like ".gitkeep" and the "cost_iteration_"
        dirFiles = [
            f
            for f in dirFiles
            if not f.startswith(".") and not f.startswith("cost_iteration_")
        ]
        dirFiles.sort()
        if len(dirFiles) > 0:
            data = pd.read_csv("{}/{}".format(encoding, dirFiles[i]))
            for row in data.itertuples():
                x.append(row.Time)
                y.append(row.Cost)
            plt.plot(x, y, label="{}".format(encoding), c=color_encoding[encoding])
    plt.xlabel("Time (s)")
    plt.ylabel("Solution Cost")
    plt.legend()
    plt.title("Solutions found for the instance {}".format(i))
    plt.grid(True)
    plt.savefig("plot_instance_{}.png".format(i), transparent=False)
    plt.clf()

# this is used to plot the cost of the best solution at each iteration
for i in range(20):
    x = []
    y = []
    dirFiles = os.listdir("incremental_one_hour_step/")
    # we remove hidden file like ".gitkeep" and the "cost_iteration_"
    dirFiles = [f for f in dirFiles if f.startswith("cost")]
    if len(dirFiles) > 0:
        dirFiles.sort()
        data = pd.read_csv("incremental_one_hour_step/{}".format(dirFiles[i]))
        for row in data.itertuples():
            x.append(row.Iteration)
            y.append(row.Cost)
        marker_place = [i for i in range(len(x)) if i == 0 or y[i - 1] > y[i]]
        plt.plot(
            x,
            y,
            linestyle="--",
            marker="o",
            color="b",
            markevery=marker_place,
            label="Instance {}".format(i),
        )
    plt.xlabel("Iteration")
    # plt.xlim(bottom=0)
    plt.ylabel("Solution Cost")
    plt.legend()
    plt.title("Best solution found at each iteration for the instance {}".format(i))
    plt.grid(True)
    plt.savefig("iteration_cost_{}.png".format(i), transparent=False)
    plt.clf()


# here we plot the violin plots
running_time_result = [
    encoding
    for encoding in os.listdir(".")
    if encoding.endswith(".csv") and not os.path.isdir(encoding)
]

for result in running_time_result:
    plt.clf()
    df = pd.read_csv("{}".format(result))
    # we remove column with inf or with overtime
    df = df.replace([np.inf, sys.maxsize], np.nan)
    df = df.dropna(axis=1)
    # we need also to remove the unnamed column
    df = df.loc[:, ~df.columns.str.contains("^Unnamed")]
    sns.violinplot(data=df, cut=0, scale="width")
    plt.xlabel("Encoding")
    if "cost" in result:
        plt.ylabel("Solution Cost")
        plt.title("Cost solution found by each encoding")
        plt.grid(True)
        plt.savefig("solution_cost_{}.png".format(result), transparent=False)
    else:
        plt.ylabel("Running time (s)")
        plt.title("Running time for each encoding")
        plt.grid(True)
        plt.savefig("running_time_{}.png".format(result), transparent=False)
