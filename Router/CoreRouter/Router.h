#ifndef ROUTER_H
#define ROUTER_H

#define ROUTER_MASK 100

typedef nx_struct CoreEdgeMsg {
  nx_int16_t From;
  nx_int16_t Bcast;
  nx_int16_t Msg;
} CoreEdgeMsg_t;

typedef nx_struct EdgeCoreMsg {
  nx_int16_t From;
  nx_int16_t Bcast;
  CoreEdgeMsg_t Msg;
} EdgeCoreMsg_t;

enum {
  AM_RADIO = 8
};

#endif
