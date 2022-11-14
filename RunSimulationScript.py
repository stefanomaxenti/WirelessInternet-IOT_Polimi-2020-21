#MAXENTI STEFANO - 10526141
#CAINAZZO ELISABETTA - 10800059

print "********************************************";
print "*                                          *";
print "*             TOSSIM Script                *";
print "*                                          *";
print "********************************************";


import sys;
import time;

from TOSSIM import *;

t = Tossim([]);


topofile="topology.txt";
modelfile="meyer-heavy.txt";


print "Initializing mac....";
mac = t.mac();
print "Initializing radio channels....";
radio=t.radio();
print "    using topology file:",topofile;
print "    using noise file:",modelfile;
print "Initializing simulator....";
t.init();

out = sys.stdout;

#Add debug channel
print "Activate debug message on channel init"
t.addChannel("init",out);
print "Activate debug message on channel boot"
t.addChannel("boot",out);
print "Activate debug message on channel radio"
t.addChannel("radio",out);

time = t.ticksPerSecond()

print "Creating AP base station 1...";
node1 =t.getNode(1);
time1 = 0*time; #instant at which each node should be turned on
node1.bootAtTime(time1);
print ">>>Will boot at time",  time1/t.ticksPerSecond(), "[sec]";

print "Creating node 2...";
node2 = t.getNode(2);
time2 = 0*time;
node2.bootAtTime(time2);
print ">>>Will boot at time", time2/t.ticksPerSecond(), "[sec]";

print "Creating node 3...";
node3 = t.getNode(3);
time3 = 0*time;
node3.bootAtTime(time3);
print ">>>Will boot at time", time3/t.ticksPerSecond(), "[sec]";

print "Creating node 4...";
node4 = t.getNode(4);
time4 = 0*time;
node4.bootAtTime(time4);
print ">>>Will boot at time", time4/t.ticksPerSecond(), "[sec]";

print "Creating node 5...";
node5 = t.getNode(5);
time5 = 0*time;
node5.bootAtTime(time5);
print ">>>Will boot at time", time5/t.ticksPerSecond(), "[sec]";

print "Creating node 6...";
node6 = t.getNode(6);
time6 = 0*time;
node6.bootAtTime(time6);
print ">>>Will boot at time", time6/t.ticksPerSecond(), "[sec]";


print "Creating radio channels..."
f = open(topofile, "r");
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print ">>>Setting radio channel from node ", s[0], " to node ", s[1], " with gain ", s[2], " dBm"
    radio.add(int(s[0]), int(s[1]), float(s[2]))


#creation of channel model
print "Initializing Closest Pattern Matching (CPM)...";
noise = open(modelfile, "r")
lines = noise.readlines()
compl = 0;
mid_compl = 0;

print "Reading noise model data file:", modelfile;
print "Loading:",
for line in lines:
    str = line.strip()
    if (str != "") and ( compl < 10000 ):
        val = int(str)
        mid_compl = mid_compl + 1;
        if ( mid_compl > 5000 ):
            compl = compl + mid_compl;
            mid_compl = 0;
            sys.stdout.write ("#")
            sys.stdout.flush()
        for i in range(1, 7):
            t.getNode(i).addNoiseTraceReading(val)
print "Done!";

for i in range(1, 7):
    print ">>>Creating noise model for node:",i;
    t.getNode(i).createNoiseModel()

print "Start simulation with TOSSIM! \n\n\n";

for i in range(0,3000000):
	t.runNextEvent()

print "\n\n\nSimulation finished!";
