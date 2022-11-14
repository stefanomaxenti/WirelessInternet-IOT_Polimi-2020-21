//MAXENTI STEFANO      10526141
//CAINAZZO ELISABETTA  10800059
#define POISSON 1
#define APPROX 1
#define PERIODIC 0
#ifndef _ACKs
  #define _ACKs 0
#endif
#ifndef _RTS_CTS
  #define _RTS_CTS 1
#endif
#ifndef _MAX_NUMBER_OF_PACKETS
  #define _MAX_NUMBER_OF_PACKETS 10000
#endif
#define _SERVER_TOS_ID 1
#ifndef _RTS_TIMEOUT
  #define _RTS_TIMEOUT 0.06
#endif
#define NUMBER_OF_MOTES 6
#ifndef _LAMBDA
  #define _LAMBDA 100
#endif
#ifndef _SIMULATION_TOSSIM
  #define _SIMULATION_TOSSIM 0
#endif


#include "mote.h"
#include "Timer.h"

module moteC {
  uses {
  /****** INTERFACES *****/
	interface Boot;
	interface SplitControl;

	interface Packet;
  interface PacketAcknowledgements as Acks;

	//interfaces for communication
	interface Receive;
  interface AMSend;

  //interface for timer
  interface Timer<TMilli> as PacketGeneratorTimer;
  interface Timer<TMilli> as PacketSendTimer;
  interface Timer<TMilli> as RTSTimer;

	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }
}

implementation {

  uint8_t pkt = 0; //flag to indicate a transmission is going on
  uint32_t counter = 0; //packet counter of clients
  uint32_t counter_rcv[NUMBER_OF_MOTES]; //counter of received packets on the base station

  message_t packet; //packet that is created
  uint16_t lambda = _LAMBDA; // average number of packets per second

  //used for better approximation
  float delta_simulation = 0;
  float delta_sum = 0;
  float delta2 = 0;

  //Function to start the mote
  event void Boot.booted() {
      dbg("boot","Application booted on mote %d.\n", TOS_NODE_ID);
	    call SplitControl.start();
  }

  //Function called after boot
  event void SplitControl.startDone(error_t err){
    if (err == SUCCESS) {
      dbg("radio","RADIO ON on mote %d.", TOS_NODE_ID);
      if (TOS_NODE_ID != _SERVER_TOS_ID) {
        dbg("radio", "Start sending requests.\n");
        #if POISSON
        call Read.read();
        #elif PERIODIC
        call PacketGeneratorTimer.startPeriodic(50);
        #endif
      } else {
        dbg("radio", "\n");
      }
    }
    else {
      dbg("radio","Radio error.Restart.\n");
      call SplitControl.start();
    }
  }

  //Function for creating and sending a RTS.
  //After that, it waits for a timeout to send the RTS again unless stopped.
  void sendRTS() {
    my_msg_t* msg = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
    if (msg == NULL)
        return;

    msg->msg_type = RTS;
    msg->source = TOS_NODE_ID;
    msg->value = TOS_NODE_ID;

    dbg("radio", "Sending RTS\n");
    pkt = 0;
    call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(my_msg_t));
    call RTSTimer.startOneShot(_RTS_TIMEOUT*1000);
  }

  //Function after RTSTimer is fired
  event void RTSTimer.fired() {
    sendRTS();
  }

  //Function for sending an actual packet (type PKT) with a payload.
  void sendPkt() {

  	my_msg_t* msg = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
    if (msg == NULL)
		    return;

    msg->msg_type = PKT;
    msg->msg_counter = counter;
    msg->value = TOS_NODE_ID;
    msg->source = TOS_NODE_ID;
    counter++;
    pkt = 1;

    #if _ACKs
    call Acks.requestAck(&packet); //Set the ACK flag
    #endif
    #if _SIMULATION_TOSSIM //approximation in simulation
    delta_simulation = sim_time()/(float)sim_ticks_per_sec();
    #endif
    call AMSend.send(_SERVER_TOS_ID, &packet, sizeof(my_msg_t));
  }

  //Function after PacketSendTimer is fired
  event void PacketSendTimer.fired() {
    sendPkt();
  }

  //Function after PacketGeneratorTimer is fired
  event void PacketGeneratorTimer.fired() {
    if (counter == _MAX_NUMBER_OF_PACKETS) {
      #if _RTS_CTS
      call RTSTimer.stop();
      #endif
      call PacketGeneratorTimer.stop();
      call SplitControl.stop();
      return;
    }
    #if _RTS_CTS
    call RTSTimer.startOneShot(0);
    #else
    //sendPkt();
    call PacketSendTimer.startOneShot(0);
    #endif
  }

  //Function called after a succesful sending
  event void AMSend.sendDone(message_t* bufPtr ,error_t err) {
    if (TOS_NODE_ID != _SERVER_TOS_ID && pkt == 1) {
      #if POISSON
      #if _SIMULATION_TOSSIM
      delta_simulation = sim_time()/(float)sim_ticks_per_sec() - delta_simulation;
      #endif
      call Read.read();
      #endif
    }
  	if(&packet == bufPtr){
  		dbg("radio", "Packet %d was correctly sent at %s\n", counter, sim_time_string());
    #if _ACKs
  		if (call Acks.wasAcked(bufPtr))
  			dbg("radio", "Mote %d received the ACK\n", TOS_NODE_ID);
      #endif
  	} else {
  		dbgerror("radio","Radio error!\n");
  	}
  }

  //Function for receiving and analyzing a packet
  event message_t* Receive.receive(message_t* bufPtr ,void* payload, uint8_t len) {
    #if _RTS_CTS
  	if (len != sizeof(my_msg_t)){
  		dbgerror("radio", "Packet malformed\n");
  		return bufPtr;
  	} else {
      my_msg_t* msg = (my_msg_t*) payload;
      if (msg->msg_type == RTS)
        dbg("radio", "Received a message of type RTS on mote %d at %s.\n", TOS_NODE_ID, sim_time_string());
      else if (msg->msg_type == CTS)
        dbg("radio", "Received a message of type CTS on mote %d at %s.\n", TOS_NODE_ID, sim_time_string());
      else
        dbg("radio", "Received a message of type PKT on mote %d at %s.\n", TOS_NODE_ID, sim_time_string());

      if (TOS_NODE_ID == _SERVER_TOS_ID) { //If we are the base station
        if (msg->msg_type == RTS) { //if packet type is RTS
          //Sending CTS in broadcast
          my_msg_t* msg2 = (my_msg_t*)call Packet.getPayload(&packet, sizeof(my_msg_t));
          if (msg2 == NULL)
              return;
          msg2->msg_type = CTS;
          msg2->source = TOS_NODE_ID;
          msg2->value = msg->source;

          call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(my_msg_t));

        } else { //if packet type is PKT
          counter_rcv[msg->source]++;
          dbg_clear("radio", "****** Total packets received from source %d: %d\n", msg->source, counter_rcv[msg->source]);
        }
    	} //end (if TOS_NODE_ID == 0)
      else { // if we are a mote (not the base station)
        //We receive a CTS not requested by us
        if (msg->msg_type == CTS && msg->value != TOS_NODE_ID) {
          call PacketSendTimer.stop();
          call RTSTimer.stop();
          call RTSTimer.startOneShot(_RTS_TIMEOUT*1000);
        } //We receive a CTS requested by us
          else if (msg->msg_type == CTS && msg->value == TOS_NODE_ID){
          call RTSTimer.stop();
          call PacketSendTimer.startOneShot(0);
        } //We receive a RTS that was sent in broadcast
          else if (msg->msg_type == RTS) {
          call RTSTimer.stop();
          call PacketSendTimer.stop();
          call RTSTimer.startOneShot(_RTS_TIMEOUT*1000);
        }
      }
    }
    #else //we are not using RTS/CTS
    if (len != sizeof(my_msg_t)){
  		dbgerror("radio", "Packet malformed\n");
  		return bufPtr;
  	} else {
      my_msg_t* msg = (my_msg_t*) payload;
      dbg("radio", "Received a message on mote %d at %s.\n", TOS_NODE_ID, sim_time_string());
      if (TOS_NODE_ID == _SERVER_TOS_ID) {
        counter_rcv[msg->source]++;
        dbg_clear("radio", "****** Total packets received from source %d: %d\n", msg->source, counter_rcv[msg->source]);
      }
    }
    #endif
    return bufPtr;
  }

  //Function to generate a random interarrival time with some approximations
  event void Read.readDone(error_t result, uint16_t r_value) {
    float exp_int_time = (1000*(-1.0/lambda))*logf(r_value/65535.0);
    //dbg_clear("radio", "random: %f on mote %d and delta %f\n", exp_int_time, TOS_NODE_ID, 1000*delta_simulation);
    #if APPROX
    delta_sum += 1000*delta_simulation;
    exp_int_time -= (1000*delta_simulation+1000*delta2);
    if (exp_int_time < 0) {
      delta2 = -exp_int_time/1000;
      exp_int_time = 0;
    } else {
      delta2 = 0;
    }
    #endif
    call PacketGeneratorTimer.startOneShot(exp_int_time);
  }

  //Function for switching the mote off
  event void SplitControl.stopDone(error_t err){
  	if (err == SUCCESS)
  		dbg("radio", "Simulation can end\n");
  	else
  		dbg("radio", "Simulation ended with error\n");
    //dbg("boot", "avg service time: %f", delta_sum / counter);
  	return;
  }
}
