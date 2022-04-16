#!/bin/bash

#make && make pthreads

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

gcc -O3 $SCRIPT_DIR/plot.c -o $SCRIPT_DIR/plot

function test() {
    # Title, exec, exec_pthread, nb, nb_exp, arg
    TITLE=$1
    EXEC=$2
    EXEC_PTHREAD=$3
    NB=$4
    NB_EXP=$5
    ARG=$6

    rm -rf "$SCRIPT_DIR/data_$EXEC" "$SCRIPT_DIR/data_$EXEC_PTHREAD"

    taskset -c 0 $SCRIPT_DIR/plot "$SCRIPT_DIR/data_$EXEC" "$NB" "$NB_EXP" "$SCRIPT_DIR/../install/bin/$EXEC" $ARG
    taskset -c 0 $SCRIPT_DIR/plot "$SCRIPT_DIR/data_$EXEC_PTHREAD" "$NB" "$NB_EXP" "$SCRIPT_DIR/../install/bin/$EXEC_PTHREAD" $ARG

    gnuplot -e "set terminal pngcairo size 1120,630 enhanced font 'Verdana,10'; set title '$TITLE'; set output '$SCRIPT_DIR/$EXEC.png'; set style data boxplot; set style boxplot medianlinewidth 2.0 nooutlier; set xtics ('Temps Réel' 1, 'Temps Réel Pthread' 2, 'Temps User' 3, 'Temps User Pthread' 4, 'Temps Système' 5, 'Temps Système Pthread' 6); plot '$SCRIPT_DIR/data_$EXEC' using (1.0):1 notitle, '$SCRIPT_DIR/data_$EXEC_PTHREAD' using (2.0):1 notitle, '$SCRIPT_DIR/data_$EXEC' using (3.0):2 notitle, '$SCRIPT_DIR/data_$EXEC_PTHREAD' using (4.0):2 notitle, '$SCRIPT_DIR/data_$EXEC' using (5.0):3 notitle, '$SCRIPT_DIR/data_$EXEC_PTHREAD' using (6.0):3 notitle"

}

test "01-main" "01-main" "01-main-pthread" 100 10
test "02-switch" "02-switch" "02-switch-pthread" 100 10
test "03-equity" "03-equity" "03-equity-pthread" 100 10
test "11-join" "11-join" "11-join-pthread" 100 10
test "12-join-main" "12-join-main" "12-join-main-pthread" 100 10
test "21-create-many" "21-create-many" "21-create-many-pthread" 100 10 1000
test "22-create-many-recursive" "22-create-many-recursive" "22-create-many-recursive-pthread" 100 10 1000
test "23-create-many-once" "23-create-many-once" "23-create-many-once-pthread" 100 10 1000
