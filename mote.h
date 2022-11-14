//MAXENTI STEFANO      10526141
//CAINAZZO ELISABETTA  10800059

#ifndef MOTE_H
#define MOTE_H

//payload of the msg
typedef nx_struct my_msg{
	nx_uint8_t msg_type; //REQ = 0 and RESP = 1
	nx_uint16_t msg_counter;
	nx_uint16_t value;
	nx_uint16_t source;
	nx_uint16_t destination;
} my_msg_t;

#define RTS 0
#define CTS 1
#define PKT 2

enum{
	AM_MY_MSG = 6,
};

#endif
