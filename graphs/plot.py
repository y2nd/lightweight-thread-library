from os import listdir
from os.path import isfile, join
import time
import resource
from subprocess import run
import numpy as np
import matplotlib.pyplot as plt

files = [join("install/bin", f) for f in listdir("install/bin") if isfile(join("install/bin", f)) and not f.endswith("-pthread")]

def benchmark_program(file, nb=1):
    times = []
    for n in range(nb):
        start = time.time()
        run(["/usr/bin/taskset", "0x00000001", file])
        end = time.time()
        times.append(end - start)
    return times

def benchmark_program_user(file, nb=1):
    times = []
    for n in range(nb):
        start = resource.getrusage(resource.RUSAGE_SELF)
        run(["/usr/bin/taskset", "0x00000001", file])
        end = resource.getrusage(resource.RUSAGE_SELF)
        times.append(end.ru_utime - start.ru_utime)
    return times

def benchmark_program_system(file, nb=1):
    times = []
    for n in range(nb):
        start = resource.getrusage(resource.RUSAGE_SELF)
        run(["/usr/bin/taskset", "0x00000001", file])
        end = resource.getrusage(resource.RUSAGE_SELF)
        times.append(end.ru_stime - start.ru_stime)
    return times

for file in files:
    REAL_implementation = benchmark_program_user(file, 200)
    REAL_pthread = benchmark_program_user(file + "-pthread", 200)
    USER_implementation = benchmark_program_user(file, 200)
    USER_pthread = benchmark_program_user(file + "-pthread", 200)
    SYSTEM_implementation = benchmark_program_system(file, 200)
    SYSTEM_pthread = benchmark_program_system(file + "-pthread", 200)

    print(np.min(USER_implementation))

    implementation = [np.mean(REAL_implementation), np.median(REAL_implementation), np.min(REAL_implementation), np.max(REAL_implementation), np.mean(USER_implementation), np.median(USER_implementation), np.min(USER_implementation), np.max(USER_implementation), np.mean(SYSTEM_implementation), np.median(SYSTEM_implementation), np.min(SYSTEM_implementation), np.max(SYSTEM_implementation)]
    pthread = [np.mean(REAL_pthread), np.median(REAL_pthread), np.min(REAL_pthread), np.max(REAL_pthread), np.mean(USER_pthread), np.median(USER_pthread), np.min(USER_pthread), np.max(USER_pthread), np.mean(SYSTEM_pthread), np.median(SYSTEM_pthread), np.min(SYSTEM_pthread), np.max(SYSTEM_pthread)]

    labels = ["Temps réel median", "Temps réel moyen", "Temps réel min", "Temps réel max", "Temps User median", "Temps User moyen", "Temps User min", "Temps User max", "Temps System median", "Temps System moyen", "Temps System min", "Temps System max"]

    fig, ax = plt.subplots()
    rects1 = ax.bar(np.arange(12) - 0.2, implementation, 0.4, label="Implementation")
    rects2 = ax.bar(np.arange(12) + 0.2, pthread, 0.4, label="pthread")

    ax.set_title(file)
    ax.set_xticks(range(12), labels)
    ax.legend()

    fig.tight_layout()

    plt.show()