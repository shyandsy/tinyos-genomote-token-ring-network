#ifndef ROUTER_H
#define ROUTER_H

typedef nx_struct RouterMsg {
  nx_int16_t From;
  nx_int16_t Bcast;
  nx_int16_t Msg;
} RouterMsg_t;

enum {
  AM_RADIO = 8
};

#endif
