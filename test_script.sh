#!/bin/sh

N=6

echo "**** IoT+WI Joint Prj 2 - The (Hidden) Terminal ****"
echo "Stefano Maxenti     - 10526141"
echo "Elisabetta Cainazzo - 10800059"
echo "Each station sends 10.000 packets to the AP (mote 1)\n"
echo "RTS/CTS disabled:\n"

echo "Compiling...\n"
make -f Makefile-NoRTS micaz sim > /dev/null 2>&1
echo "Running...\n"
python RunSimulationScript.py > log/simulation_norts.txt

for i in $(seq 1 1 $N)
do
	grep "source $i" log/simulation_norts.txt | tail -1
done

echo "\n\n"

echo "RTS/CTS enabled:\n"
echo "Compiling...\n"
make -f Makefile-RTS micaz sim > /dev/null 2>&1
echo "Running...\n"
python RunSimulationScript.py > log/simulation_rts.txt


for i in $(seq 1 1 $N)
do
	grep "source $i" log/simulation_rts.txt | tail -1
done
