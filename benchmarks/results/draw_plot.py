import matplotlib.pyplot as plt
import os
import pandas as pd

for i in range(13):
    for enconding in os.listdir('.'):
        x = []
        y = []
        if os.path.isdir(enconding):
            data = pd.read_csv("{}/{}.csv".format(enconding, i)) 
            for row in data.itertuples():
                x.append(row.Time)
                y.append(row.Cost)
            plt.plot(x, y, label="{}".format(enconding))
    plt.xlabel("Time (s)")
    plt.ylabel("Solution Cost")
    plt.legend()
    plt.grid(True)
    plt.savefig("plot_instance_{}.png".format(i), transparent=True)
    plt.clf()