from os import listdir
from os.path import isfile, join
import time
import resource
from subprocess import run, DEVNULL
import numpy as np
import matplotlib.pyplot as plt

files = [join("install/bin", f) for f in listdir("install/bin")
         if isfile(join("install/bin", f)) and not f.endswith("-pthread")]


def benchmark_program(file, nb=1):
    times = []
    for n in range(0, nb):
        start = time.time_ns()
        run(["/usr/bin/taskset", "0x00000001", file],
            stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL)
        end = time.time_ns()
        times.append((end - start) * 10**-9)
    return times


def benchmark_program_user(file, nb=1):
    times = []
    for n in range(nb):
        start = resource.getrusage(resource.RUSAGE_CHILDREN)
        run(["/usr/bin/taskset", "0x00000001", file],
            stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL)
        end = resource.getrusage(resource.RUSAGE_CHILDREN)
        times.append(end.ru_utime - start.ru_utime)
    return times


def benchmark_program_system(file, nb=1):
    times = []
    for n in range(nb):
        start = resource.getrusage(resource.RUSAGE_CHILDREN)
        run(["/usr/bin/taskset", "0x00000001", file],
            stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL)
        end = resource.getrusage(resource.RUSAGE_CHILDREN)
        times.append(end.ru_stime - start.ru_stime)
    return times


for file in files:
    REAL_implementation = benchmark_program_user(file, 1000)
    REAL_pthread = benchmark_program_user(file + "-pthread", 1000)
    USER_implementation = benchmark_program_user(file, 1000)
    USER_pthread = benchmark_program_user(file + "-pthread", 1000)
    SYSTEM_implementation = benchmark_program_system(file, 1000)
    SYSTEM_pthread = benchmark_program_system(file + "-pthread", 1000)

    print(np.min(USER_implementation))

    implementation = [np.mean(REAL_implementation), np.median(REAL_implementation), np.min(REAL_implementation), np.max(REAL_implementation), np.mean(USER_implementation), np.median(USER_implementation), np.min(
        USER_implementation), np.max(USER_implementation), np.mean(SYSTEM_implementation), np.median(SYSTEM_implementation), np.min(SYSTEM_implementation), np.max(SYSTEM_implementation)]
    pthread = [np.mean(REAL_pthread), np.median(REAL_pthread), np.min(REAL_pthread), np.max(REAL_pthread), np.mean(USER_pthread), np.median(USER_pthread), np.min(
        USER_pthread), np.max(USER_pthread), np.mean(SYSTEM_pthread), np.median(SYSTEM_pthread), np.min(SYSTEM_pthread), np.max(SYSTEM_pthread)]

    plt.boxplot([REAL_implementation, REAL_pthread, USER_implementation,
                USER_pthread, SYSTEM_implementation, SYSTEM_pthread], labels=["Temps réel", "Temps réel Pthread", "Temps CPU", "Temp CPU Pthread", "Temps système", "Temps système Pthread"])
    plt.show()
