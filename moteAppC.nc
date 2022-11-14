//MAXENTI STEFANO      10526141
//CAINAZZO ELISABETTA  10800059

#include "mote.h"

configuration moteAppC {

}

implementation {

/***** COMPONENTS *****/
  components MainC, moteC as App;
  components new RandomGeneratorC();
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components new TimerMilliC() as PacketGeneratorTimerC;
  components new TimerMilliC() as PacketSendTimerC;
  components new TimerMilliC() as RTSTimerC;
  components ActiveMessageC;
  components SerialStartC;

/***** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;


  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Timer interface
  App.PacketGeneratorTimer -> PacketGeneratorTimerC;
  App.PacketSendTimer -> PacketSendTimerC;
  App.RTSTimer -> RTSTimerC;

  //Interfaces to access package fields
  App.Packet -> AMSenderC;
  App.Acks->ActiveMessageC;

  //Fake Sensor read
  App.Read -> RandomGeneratorC;
}
