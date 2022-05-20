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

function complexity() {
    # Title, exec, nb, range, args
    TITLE=$1
    EXEC=$2
    NB=$3
    RANGE=$4
    ARG=$5

    rm -rf "$SCRIPT_DIR/data_plot_$EXEC"

    for VALUE in $RANGE
    do
        echo "install/bin/$EXEC $VALUE $ARG"
        echo -e "$VALUE\t$(LD_LIBRARY_PATH="$SCRIPT_DIR/../install/lib/:$LD_LIBRARY_PATH" time taskset -c 0 $SCRIPT_DIR/plot "/dev/stdout" "$NB" 1 "$SCRIPT_DIR/../install/bin/$EXEC" $VALUE $ARG)" >> $SCRIPT_DIR/data_plot_$EXEC
    done

    gnuplot -e "set terminal pngcairo size 1120,630 enhanced font 'Verdana,10'; set title '$(echo $EXEC | sed 's/_/\\_/g')'; set output '$SCRIPT_DIR/$TITLE.png'; set style line 1 linecolor rgb '#0060ad' linetype 1 linewidth 2; plot '$SCRIPT_DIR/data_plot_$EXEC' using 1:2 with linespoint"
}

function complexity_fibo() {
    # Title, exec, nb, max
    TITLE=$1
    EXEC=$2
    NB=$3
    MAX=$4

    V1=1
    V2=2

    rm -rf "$SCRIPT_DIR/data_plot_$EXEC"

    for VALUE in $(seq 3 $MAX)
    do
        echo "install/bin/$EXEC $VALUE - Threads : $V2"
        echo -e "$V2\t$(LD_LIBRARY_PATH="$SCRIPT_DIR/../install/lib/:$LD_LIBRARY_PATH" time taskset -c 0 $SCRIPT_DIR/plot "/dev/stdout" "$NB" 1 "$SCRIPT_DIR/../install/bin/$EXEC" $VALUE)" >> $SCRIPT_DIR/data_plot_$EXEC
        TEMP=$V2
        V2=$(($V1+$V2))
        V1=$TEMP
    done

    gnuplot -e "set terminal pngcairo size 1120,630 enhanced font 'Verdana,10'; set title '$(echo $EXEC | sed 's/_/\\_/g')'; set output '$SCRIPT_DIR/$TITLE.png'; set style line 1 linecolor rgb '#0060ad' linetype 1 linewidth 2; plot '$SCRIPT_DIR/data_plot_$EXEC' using 1:2 with linespoint"
}

function complexity2() {
    # Title, exec, nb, range, args
    TITLE=$1
    EXEC=$2
    NB=$3
    ARG1=$4
    RANGE=$5
    ARG=$6

    rm -rf "$SCRIPT_DIR/data_plot_$EXEC"

    for VALUE in $RANGE
    do
        echo "install/bin/$EXEC $ARG1 $VALUE $ARG"
        echo -e "$VALUE\t$(LD_LIBRARY_PATH="$SCRIPT_DIR/../install/lib/:$LD_LIBRARY_PATH" time taskset -c 0 $SCRIPT_DIR/plot "/dev/stdout" "$NB" 1 "$SCRIPT_DIR/../install/bin/$EXEC" $ARG1 $VALUE $ARG)" >> $SCRIPT_DIR/data_plot_$EXEC
    done

    gnuplot -e "set terminal pngcairo size 1120,630 enhanced font 'Verdana,10'; set title '$(echo $EXEC | sed 's/_/\\_/g')'; set output '$SCRIPT_DIR/$TITLE.png'; set style line 1 linecolor rgb '#0060ad' linetype 1 linewidth 2; plot '$SCRIPT_DIR/data_plot_$EXEC' using 1:2 with linespoint"
}

#SUFFIXE=p
#SUFFIXE1=
#
#complexity "${SUFFIXE}21-create-many" "21-create-many$SUFFIXE1" 50 "$(seq 1000 1000 1000)"
#complexity "${SUFFIXE}22-create-many-recursive" "22-create-many-recursive$SUFFIXE1" 50 "$(seq 1000 1000 1000)"
#complexity "${SUFFIXE}23-create-many-once" "23-create-many-once$SUFFIXE1" 50 "$(seq 1000 1000 1000)"
#complexity2 "${SUFFIXE}31-switch-many" "31-switch-many$SUFFIXE1" 100 "10" "$(seq 1000 1000 1000)"
#complexity "${SUFFIXE}31-switch-many2" "31-switch-many$SUFFIXE1" 100 "$(seq 1000 1000 1000)" "10"
#complexity2 "${SUFFIXE}32-switch-many-join" "32-switch-many-join$SUFFIXE1" 100 "10" "$(seq 1000 1000 1000)"
#complexity "${SUFFIXE}32-switch-many-join2" "32-switch-many-join$SUFFIXE1" 100 "$(seq 1000 1000 1000)" "10"
#complexity2 "${SUFFIXE}33-switch-many-cascade" "33-switch-many-cascade$SUFFIXE1" 100 "10" "$(seq 1000 1000 1000)"
#complexity "${SUFFIXE}33-switch-many-cascade2" "33-switch-many-cascade$SUFFIXE1" 100 "$(seq 10 30 300)" 10
#complexity_fibo "${SUFFIXE}51-fibonacci" "51-fibonacci$SUFFIXE1" 1 25

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
#test3 "${SUFFIXE}21-create-many" "21-create-many$SUFFIXE1" "21-create-many$SUFFIXE2" "21-create-many$SUFFIXE3" 1 50 "1000"
#test3 "${SUFFIXE}22-create-many-recursive" "22-create-many-recursive$SUFFIXE1" "22-create-many-recursive$SUFFIXE2" "22-create-many-recursive$SUFFIXE3" 1 50 "1000"
#test3 "${SUFFIXE}23-create-many-once" "23-create-many-once$SUFFIXE1" "23-create-many-once$SUFFIXE2" "23-create-many-once$SUFFIXE3" 1 50 "1000"
#test3 "${SUFFIXE}31-switch-many" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" "31-switch-many$SUFFIXE3" 10 100 "10 1000"
#test3 "${SUFFIXE}31-switch-many2" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" "31-switch-many$SUFFIXE3" 10 100 "1000 10"
#test3 "${SUFFIXE}32-switch-many-join" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" "32-switch-many-join$SUFFIXE3" 10 100 "10 1000"
#test3 "${SUFFIXE}32-switch-many-join2" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" "32-switch-many-join$SUFFIXE3" 10 100 "1000 10"
#test3 "${SUFFIXE}33-switch-many-cascade" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" "33-switch-many-cascade$SUFFIXE3" 10 100 "10 1000"
#test3 "${SUFFIXE}33-switch-many-cascade2" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" "33-switch-many-cascade$SUFFIXE3" 10 100 "200 10"
#test3 "${SUFFIXE}reduction" "reduction$SUFFIXE1" "reduction$SUFFIXE2" "reduction$SUFFIXE3" 10 100
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
#test "${SUFFIXE}21-create-many" "21-create-many$SUFFIXE1" "21-create-many$SUFFIXE2" 1 50 "1000"
#test "${SUFFIXE}22-create-many-recursive" "22-create-many-recursive$SUFFIXE1" "22-create-many-recursive$SUFFIXE2" 1 50 "1000"
#test "${SUFFIXE}23-create-many-once" "23-create-many-once$SUFFIXE1" "23-create-many-once$SUFFIXE2" 1 50 "1000"
#test "${SUFFIXE}31-switch-many" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 "10 1000"
#test "${SUFFIXE}31-switch-many2" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 "1000 10"
#test "${SUFFIXE}32-switch-many-join" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 "10 1000"
#test "${SUFFIXE}32-switch-many-join2" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 "1000 10"
#test "${SUFFIXE}33-switch-many-cascade" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 "10 1000"
#test "${SUFFIXE}33-switch-many-cascade2" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 "200 10"
#test "${SUFFIXE}reduction" "reduction$SUFFIXE1" "reduction$SUFFIXE2" 10 100
#
#
#T_MEM_POOL=yes Q_MEM_POOL=yes SCHED=FIFO make
#T_MEM_POOL=no Q_MEM_POOL=no SCHED=FIFO make
#

make
PREEMPT_GLOBAL=no make

SUFFIXE=c
SUFFIXE1=-preempt_global_no
SUFFIXE2=-preempt_global_no

test "${SUFFIXE}01-main" "01-main$SUFFIXE1" "01-main$SUFFIXE2" 10 100
test "${SUFFIXE}02-switch" "02-switch$SUFFIXE1" "02-switch$SUFFIXE2" 10 100
test "${SUFFIXE}03-equity" "03-equity$SUFFIXE1" "03-equity$SUFFIXE2" 10 100
test "${SUFFIXE}11-join" "11-join$SUFFIXE1" "11-join$SUFFIXE2" 10 100
test "${SUFFIXE}12-join-main" "12-join-main$SUFFIXE1" "12-join-main$SUFFIXE2" 10 100
test "${SUFFIXE}21-create-many" "21-create-many$SUFFIXE1" "21-create-many$SUFFIXE2" 1 50 "1000"
test "${SUFFIXE}22-create-many-recursive" "22-create-many-recursive$SUFFIXE1" "22-create-many-recursive$SUFFIXE2" 1 50 "1000"
test "${SUFFIXE}23-create-many-once" "23-create-many-once$SUFFIXE1" "23-create-many-once$SUFFIXE2" 1 50 "1000"
test "${SUFFIXE}31-switch-many" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 "10 1000"
test "${SUFFIXE}31-switch-many2" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 "1000 10"
test "${SUFFIXE}32-switch-many-join" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 "10 1000"
test "${SUFFIXE}32-switch-many-join2" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 "1000 10"
test "${SUFFIXE}33-switch-many-cascade" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 "10 1000"
test "${SUFFIXE}33-switch-many-cascade2" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 "200 10"
