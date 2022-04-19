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
    time taskset -c 0 $SCRIPT_DIR/plot "$SCRIPT_DIR/data_$EXEC" "$NB" "$NB_EXP" "$SCRIPT_DIR/../install/bin/$EXEC" $ARG
    echo "$EXEC_PTHREAD"
    time taskset -c 0 $SCRIPT_DIR/plot "$SCRIPT_DIR/data_$EXEC_PTHREAD" "$NB" "$NB_EXP" "$SCRIPT_DIR/../install/bin/$EXEC_PTHREAD" $ARG

    [ -e "$SCRIPT_DIR/$TITLE.png" ] && mv "$SCRIPT_DIR/$TITLE.png" "$SCRIPT_DIR/$TITLE.old.png"

    gnuplot -e "set terminal pngcairo size 1120,630 enhanced font 'Verdana,10'; set title '$EXEC vs $EXEC_PTHREAD'; set output '$SCRIPT_DIR/$TITLE.png'; set style data boxplot; set style boxplot medianlinewidth 2.0 nooutlier; set xtics ('Temps Réel' 1, 'Temps Réel Pthread' 2, 'Temps User' 3, 'Temps User Pthread' 4, 'Temps Système' 5, 'Temps Système Pthread' 6); plot '$SCRIPT_DIR/data_$EXEC' using (1.0):1 notitle, '$SCRIPT_DIR/data_$EXEC_PTHREAD' using (2.0):1 notitle, '$SCRIPT_DIR/data_$EXEC' using (3.0):2 notitle, '$SCRIPT_DIR/data_$EXEC_PTHREAD' using (4.0):2 notitle, '$SCRIPT_DIR/data_$EXEC' using (5.0):3 notitle, '$SCRIPT_DIR/data_$EXEC_PTHREAD' using (6.0):3 notitle"

}

SUFFIXE1=
SUFFIXE2=-pthread

test "01-main" "01-main$SUFFIXE1" "01-main$SUFFIXE2" 10 100
test "02-switch" "02-switch$SUFFIXE1" "02-switch$SUFFIXE2" 10 100
test "03-equity" "03-equity$SUFFIXE1" "03-equity$SUFFIXE2" 10 100
test "11-join" "11-join$SUFFIXE1" "11-join$SUFFIXE2" 10 100
test "12-join-main" "12-join-main$SUFFIXE1" "12-join-main$SUFFIXE2" 10 100
test "21-create-many" "21-create-many$SUFFIXE1" "21-create-many$SUFFIXE2" 1 50 10000
test "22-create-many-recursive" "22-create-many-recursive$SUFFIXE1" "22-create-many-recursive$SUFFIXE2" 1 50 10000
test "23-create-many-once" "23-create-many-once$SUFFIXE1" "23-create-many-once$SUFFIXE2" 1 50 10000
test "31-switch-many" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 10 10000
test "31-switch-many2" "31-switch-many$SUFFIXE1" "31-switch-many$SUFFIXE2" 10 100 10000 10
test "32-switch-many-join" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 10 10000
test "32-switch-many-join2" "32-switch-many-join$SUFFIXE1" "32-switch-many-join$SUFFIXE2" 10 100 10000 10
test "33-switch-many-cascade" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 10 10000
test "33-switch-many-cascade2" "33-switch-many-cascade$SUFFIXE1" "33-switch-many-cascade$SUFFIXE2" 10 100 200 10
