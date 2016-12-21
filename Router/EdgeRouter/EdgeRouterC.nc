#include "Router.h"
#include <stdlib.h>
#include <stdio.h>

#define MAX_HOST_NUM 99
#define MIN_HOST_NUM 1
#define MIN_ROUTER_NUM 1
#define MAX_ROUTER_NUM 4
#define MIN_FIRE_TIME 10 // 10 sec
#define MAX_FIRE_TIME 20 // 20 sec
#define CORE_ROUTER_ID 550

module EdgeRouterC {
  uses { // GENERAL INTERFACE
    interface Boot;
    interface Leds;
    interface Random;
  }
  uses { // TIMER(S)
    interface Timer<TMilli> as Timer0;
  }

  uses { // COMMUNICATION
    interface Packet;
    interface AMPacket;
    interface AMSend;
    interface SplitControl as AMControl;
    interface Receive;
  }
}
implementation {
  int mHostLimit = -1;
  int mDestLimit = -1;
  nx_int16_t mHostTable[MAX_HOST_NUM];
  nx_int16_t mDestTable[MAX_HOST_NUM * (MAX_ROUTER_NUM-1)];

  bool mRadioBusy = FALSE;

  message_t mPacket;

  int i, j, k;
  int fireTime;

  void createTables() {
    mHostLimit = (call Random.rand32()) % (MAX_HOST_NUM + 1 - MIN_HOST_NUM) + MIN_HOST_NUM;

    for (i = 0; i < mHostLimit; i++) {
      mHostTable[i] = TOS_NODE_ID * 100 + i + 1;
    }

    mDestLimit = (MAX_ROUTER_NUM-1) * mHostLimit;

    for (i = 1; i < MAX_ROUTER_NUM; i++) {
      int edgeRouter = ((TOS_NODE_ID + i) <= MAX_ROUTER_NUM) ? TOS_NODE_ID + i : (TOS_NODE_ID + i) /  MAX_ROUTER_NUM;
      for (j = 0; j < mHostLimit; j++) {
	mDestTable[((i-1)*mHostLimit)+j] = edgeRouter * 100 + j + 1;
      }
    }
  }

  event void Boot.booted() {
    createTables();
     
    call AMControl.start();

    fireTime = ((call Random.rand32()) % (MAX_FIRE_TIME + 1 - MIN_FIRE_TIME) + MIN_FIRE_TIME) * 1000;
    call Timer0.startPeriodic(fireTime);
  }

  nx_int16_t getHostNum() {
    return mHostTable[(call Random.rand32()) % mHostLimit];
  }

  nx_int16_t getDestNum() {
    return mDestTable[(call Random.rand32()) % mDestLimit];
  };

  event void Timer0.fired() {
    if (mRadioBusy == FALSE) {
      RouterMsg_t *msg = call Packet.getPayload(&mPacket, sizeof(RouterMsg_t));
      msg->From = getHostNum();
      msg->Bcast = CORE_ROUTER_ID;
      msg->Msg = getDestNum();
      
      if (call AMSend.send(CORE_ROUTER_ID, &mPacket, sizeof(RouterMsg_t)) == SUCCESS) {
        mRadioBusy = TRUE;
        call Leds.led1Toggle();
      }
    }
  }

  event void AMSend.sendDone(message_t *msg, error_t error) {
    if(msg == &mPacket) {
      mRadioBusy = FALSE;
    }
  }

  event void AMControl.startDone(error_t error) {
    if (error != SUCCESS) {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t error) {
  }

  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    if (len == sizeof(RouterMsg_t)) {
      RouterMsg_t *incomingMsg = (RouterMsg_t *) payload;
      if (incomingMsg->Bcast / 100 == TOS_NODE_ID) {
        call Leds.led2Toggle();      
      }
    }
    return msg;
  }
}
