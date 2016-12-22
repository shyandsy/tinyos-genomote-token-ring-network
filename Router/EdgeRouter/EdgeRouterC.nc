#include "Router.h"

#define MAX_HOST_NUM 99
#define MIN_HOST_NUM 1
#define MIN_ROUTER_NUM 1
#define MAX_ROUTER_NUM 4
#define MIN_FIRE_TIME 10 // 10 sec
#define MAX_FIRE_TIME 20 // 20 sec
#define CORE_ROUTER_ID 550
#define MILLISEC 1000

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

  message_t mPacket;
  CoreEdgeMsg_t mPayload;

  int i, j;
  int fireTime;

  bool mRadioBusy = FALSE;

  void createTables() {
    mHostLimit = (call Random.rand32()) % (MAX_HOST_NUM + 1 - MIN_HOST_NUM) + MIN_HOST_NUM;

    for (i = 0; i < mHostLimit; i++) {
      mHostTable[i] = TOS_NODE_ID * ROUTER_MASK + i + 1;
    }

    mDestLimit = (MAX_ROUTER_NUM-1) * mHostLimit;

    for (i = 1; i < MAX_ROUTER_NUM; i++) {
      int eRouter = TOS_NODE_ID+i;
      eRouter = (eRouter <= MAX_ROUTER_NUM) ? eRouter : eRouter / MAX_ROUTER_NUM;
      for (j = 0; j < mHostLimit; j++) {
	mDestTable[((i-1)*mHostLimit)+j] = eRouter * ROUTER_MASK + j + 1;
      }
    }
  }

  event void Boot.booted() {
    createTables();
     
    call AMControl.start();

    fireTime = ((call Random.rand32()) % (MAX_FIRE_TIME + 1 - MIN_FIRE_TIME) + MIN_FIRE_TIME) * MILLISEC;
    call Timer0.startPeriodic(fireTime);
  }

  nx_int16_t getHostNum() {
    return mHostTable[(call Random.rand32()) % mHostLimit];
  }

  nx_int16_t getDestNum() {
    return mDestTable[(call Random.rand32()) % mDestLimit];
  };

  nx_int16_t getPayload() {
    return call Random.rand16();
  };

  event void Timer0.fired() {
    if (mRadioBusy == FALSE) {
      EdgeCoreMsg_t *msg = call Packet.getPayload(&mPacket, sizeof(EdgeCoreMsg_t));
      msg->From = getHostNum();
      msg->Bcast = CORE_ROUTER_ID;

      mPayload.From = msg->From;
      mPayload.Bcast = getDestNum();
      mPayload.Msg = getPayload();
      msg->Msg = mPayload;
      
      if (call AMSend.send(CORE_ROUTER_ID, &mPacket, sizeof(EdgeCoreMsg_t)) == SUCCESS) {
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
    if (len == sizeof(CoreEdgeMsg_t)) {
      CoreEdgeMsg_t *incomingMsg = (CoreEdgeMsg_t *) payload;
      if (incomingMsg->Bcast / ROUTER_MASK == TOS_NODE_ID) {
        call Leds.led2Toggle();      
      }
    }
    return msg;
  }
}
