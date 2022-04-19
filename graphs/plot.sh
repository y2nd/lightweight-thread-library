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

    echo "$TITLE"

    rm -rf "$SCRIPT_DIR/data_$EXEC" "$SCRIPT_DIR/data_$EXEC_PTHREAD"

    echo "$EXEC"
    LD_LIBRARY_PATH="$SCRIPT_DIR/../install/lib/:$LD_LIBRARY_PATH" time taskset -c 0 $SCRIPT_DIR/plot "$SCRIPT_DIR/data_$EXEC" "$NB" "$NB_EXP" "$SCRIPT_DIR/../install/bin/$EXEC" $ARG
    echo "$EXEC_PTHREAD"
    LD_LIBRARY_PATH="$SCRIPT_DIR/../install/lib/:$LD_LIBRARY_PATH" time taskset -c 0 $SCRIPT_DIR/plot "$SCRIPT_DIR/data_$EXEC_PTHREAD" "$NB" "$NB_EXP" "$SCRIPT_DIR/../install/bin/$EXEC_PTHREAD" $ARG

    [ -e "$SCRIPT_DIR/$TITLE.png" ] && mv "$SCRIPT_DIR/$TITLE.png" "$SCRIPT_DIR/$TITLE.old.png"

    gnuplot -e "set terminal pngcairo size 1120,630 enhanced font 'Verdana,10'; set title '$(echo $EXEC | sed 's/_/\\_/g') vs $(echo $EXEC_PTHREAD | sed 's/_/\\_/g')'; set output '$SCRIPT_DIR/$TITLE.png'; set style data boxplot; set style boxplot medianlinewidth 2.0 nooutlier; set xtics ('Temps Réel 1' 1, 'Temps Réel 2' 2, 'Temps User 1' 3, 'Temps User 2' 4, 'Temps Système 1' 5, 'Temps Système 2' 6); plot '$SCRIPT_DIR/data_$EXEC' using (1.0):1 notitle, '$SCRIPT_DIR/data_$EXEC_PTHREAD' using (2.0):1 notitle, '$SCRIPT_DIR/data_$EXEC' using (3.0):2 notitle, '$SCRIPT_DIR/data_$EXEC_PTHREAD' using (4.0):2 notitle, '$SCRIPT_DIR/data_$EXEC' using (5.0):3 notitle, '$SCRIPT_DIR/data_$EXEC_PTHREAD' using (6.0):3 notitle"

}

function test3() {
    # Title, exec, exec_1, exec_2, nb, nb_exp, arg
    TITLE=$1
    EXEC=$2
    EXEC_1=$3
    EXEC_2=$4
    NB=$5
    NB_EXP=$6
    ARG=$7

    echo "$TITLE"

    rm -rf "$SCRIPT_DIR/data_$EXEC" "$SCRIPT_DIR/data_$EXEC_PTHREAD"

    echo "$EXEC"
    LD_LIBRARY_PATH="$SCRIPT_DIR/../install/lib/:$LD_LIBRARY_PATH" time taskset -c 0 $SCRIPT_DIR/plot "$SCRIPT_DIR/data_$EXEC" "$NB" "$NB_EXP" "$SCRIPT_DIR/../install/bin/$EXEC" $ARG
    echo "$EXEC_1"
    LD_LIBRARY_PATH="$SCRIPT_DIR/../install/lib/:$LD_LIBRARY_PATH" time taskset -c 0 $SCRIPT_DIR/plot "$SCRIPT_DIR/data_$EXEC_1" "$NB" "$NB_EXP" "$SCRIPT_DIR/../install/bin/$EXEC_1" $ARG
    echo "$EXEC_2"
    LD_LIBRARY_PATH="$SCRIPT_DIR/../install/lib/:$LD_LIBRARY_PATH" time taskset -c 0 $SCRIPT_DIR/plot "$SCRIPT_DIR/data_$EXEC_2" "$NB" "$NB_EXP" "$SCRIPT_DIR/../install/bin/$EXEC_2" $ARG

    [ -e "$SCRIPT_DIR/$TITLE.png" ] && mv "$SCRIPT_DIR/$TITLE.png" "$SCRIPT_DIR/$TITLE.old.png"

    gnuplot -e "set terminal pngcairo size 1120,630 enhanced font 'Verdana,10'; set title '$(echo $EXEC | sed 's/_/\\_/g') vs $(echo $EXEC_1 | sed 's/_/\\_/g') vs $(echo $EXEC_2 | sed 's/_/\\_/g')'; set output '$SCRIPT_DIR/$TITLE.png'; set style data boxplot; set style boxplot medianlinewidth 2.0 nooutlier; set xtics ('Temps Réel 1' 1, 'Temps Réel 2' 2, 'Temps Réel 3' 3, 'Temps User 1' 4, 'Temps User 2' 5, 'Temps User 3' 6, 'Temps Système 1' 7, 'Temps Système 2' 8, 'Temps  Système 3' 9); plot '$SCRIPT_DIR/data_$EXEC' using (1.0):1 notitle, '$SCRIPT_DIR/data_$EXEC_1' using (2.0):1 notitle, '$SCRIPT_DIR/data_$EXEC_2' using (3.0):1 notitle, '$SCRIPT_DIR/data_$EXEC' using (4.0):2 notitle, '$SCRIPT_DIR/data_$EXEC_1' using (5.0):2 notitle, '$SCRIPT_DIR/data_$EXEC_2' using (6.0):2 notitle, '$SCRIPT_DIR/data_$EXEC' using (7.0):3 notitle, '$SCRIPT_DIR/data_$EXEC_1' using (8.0):3 notitle, '$SCRIPT_DIR/data_$EXEC_2' using (9.0):3 notitle"

}


#SCHED=fifo make
#SCHED=basic make
#SCHED=economy make
#
#SUFFIXE=a
#SUFFIXE1=-sched_basic
#SUFFIXE2=-sched_fifo
#SUFFIXE3=-sched_economy
#
#test3 "${SUFFIXE}01-main" "01-main$SUFFIXE1" "01-main$SUFFIXE2" "01-main$SUFFIXE3" 10 100
#test3 "${SUFFIXE}02-switch" "02-switch$SUFFIXE1" "02-switch$SUFFIXE2" "02-switch$SUFFIXE3" 10 100
#test3 "${SUFFIXE}03-equity" "03-equity$SUFFIXE1" "03-equity$SUFFIXE2" "03-equity$SUFFIXE3" 10 100
#test3 "${SUFFIXE}11-join" "11-join$SUFFIXE1" "11-join$SUFFIXE2" "11-join$SUFFIXE3" 10 100
#test3 "${SUFFIXE}12-join-main" "12-join-main$SUFFIXE1" "12-join-main$SUFFIXE2" "12-join-main$SUFFIXE3" 10 100
#test3 "${SUFFIXE}21-create-many" "21-create-many$SUFFIXE1" "21-create-many$SUFFIXE2" "21-create-many$SUFFIXE3" 1 50 1000
#test3 "${SUFFIXE}22-create-many-recursive" "22-create-many-recursive$SUFFIXE1" "22-create-many-recursive$SUFFIXE2" "22-create-many-recursive$SUFFIXE3" 1 50 1000
#test3 "${SUFFIXE}23-create-many-once" "23-create-many-once$SUFFIXE1" "23-create-many-once$SUFFIXE2" "23-create-many-once$SUFFIXE3" 1 50 1000
#test3 "${SUFFIXE}31-switch-many" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" "31-switch-many$SUFFIXE3" 10 100 10 10000
#test3 "${SUFFIXE}31-switch-many2" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" "31-switch-many$SUFFIXE3" 10 100 10000 10
#test3 "${SUFFIXE}32-switch-many-join" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" "32-switch-many-join$SUFFIXE3" 10 100 10 10000
#test3 "${SUFFIXE}32-switch-many-join2" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" "32-switch-many-join$SUFFIXE3" 10 100 10000 10
#test3 "${SUFFIXE}33-switch-many-cascade" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" "33-switch-many-cascade$SUFFIXE3" 10 100 10 10000
#test3 "${SUFFIXE}33-switch-many-cascade2" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" "33-switch-many-cascade$SUFFIXE3" 10 100 200 10
#
#Q_LOOP=yes SCHED=FIFO make
#Q_LOOP=no SCHED=FIFO make
#
#SUFFIXE=b
#SUFFIXE1=-sched_fifo-q_loop_yes
#SUFFIXE2=-sched_fifo-q_loop_no
#
#test "${SUFFIXE}01-main" "01-main$SUFFIXE1" "01-main$SUFFIXE2" 10 100
#test "${SUFFIXE}02-switch" "02-switch$SUFFIXE1" "02-switch$SUFFIXE2" 10 100
#test "${SUFFIXE}03-equity" "03-equity$SUFFIXE1" "03-equity$SUFFIXE2" 10 100
#test "${SUFFIXE}11-join" "11-join$SUFFIXE1" "11-join$SUFFIXE2" 10 100
#test "${SUFFIXE}12-join-main" "12-join-main$SUFFIXE1" "12-join-main$SUFFIXE2" 10 100
#test "${SUFFIXE}21-create-many" "21-create-many$SUFFIXE1" "21-create-many$SUFFIXE2" 1 50 10000
#test "${SUFFIXE}22-create-many-recursive" "22-create-many-recursive$SUFFIXE1" "22-create-many-recursive$SUFFIXE2" 1 50 10000
#test "${SUFFIXE}23-create-many-once" "23-create-many-once$SUFFIXE1" "23-create-many-once$SUFFIXE2" 1 50 10000
#test "${SUFFIXE}31-switch-many" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 10 10000
#test "${SUFFIXE}31-switch-many2" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 10000 10
#test "${SUFFIXE}32-switch-many-join" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 10 10000
#test "${SUFFIXE}32-switch-many-join2" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 10000 10
#test "${SUFFIXE}33-switch-many-cascade" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 10 10000
#test "${SUFFIXE}33-switch-many-cascade2" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 200 10
#

T_MEM_POOL=yes Q_MEM_POOL=yes SCHED=FIFO make
T_MEM_POOL=no Q_MEM_POOL=no SCHED=FIFO make

SUFFIXE=c
SUFFIXE1=-sched_fifo-t_mem_pool_yes-q_mem_pool_yes
SUFFIXE2=-sched_fifo-t_mem_pool_no-q_mem_pool_no

test "${SUFFIXE}01-main" "01-main$SUFFIXE1" "01-main$SUFFIXE2" 10 100
test "${SUFFIXE}02-switch" "02-switch$SUFFIXE1" "02-switch$SUFFIXE2" 10 100
test "${SUFFIXE}03-equity" "03-equity$SUFFIXE1" "03-equity$SUFFIXE2" 10 100
test "${SUFFIXE}11-join" "11-join$SUFFIXE1" "11-join$SUFFIXE2" 10 100
test "${SUFFIXE}12-join-main" "12-join-main$SUFFIXE1" "12-join-main$SUFFIXE2" 10 100
test "${SUFFIXE}21-create-many" "21-create-many$SUFFIXE1" "21-create-many$SUFFIXE2" 1 50 10000
test "${SUFFIXE}22-create-many-recursive" "22-create-many-recursive$SUFFIXE1" "22-create-many-recursive$SUFFIXE2" 1 50 10000
test "${SUFFIXE}23-create-many-once" "23-create-many-once$SUFFIXE1" "23-create-many-once$SUFFIXE2" 1 50 10000
test "${SUFFIXE}31-switch-many" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 10 10000
test "${SUFFIXE}31-switch-many2" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 10000 10
test "${SUFFIXE}32-switch-many-join" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 10 10000
test "${SUFFIXE}32-switch-many-join2" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 10000 10
test "${SUFFIXE}33-switch-many-cascade" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 10 10000
test "${SUFFIXE}33-switch-many-cascade2" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 200 10
