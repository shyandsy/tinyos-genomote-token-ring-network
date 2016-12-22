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
  int mHostLimit = -1; // for the random host limit
  int mDestLimit = -1; // destination limit that derives from host limit
  nx_int16_t mHostTable[MAX_HOST_NUM]; // holds hosts edge router in connected to
  nx_int16_t mDestTable[MAX_HOST_NUM * (MAX_ROUTER_NUM-1)]; // holds edge router/host pairs this edge router can send to

  message_t mPacket; // the packet to send over radio
  CoreEdgeMsg_t mPayload; // Msg in the packet

  int i, j; // needed for loops
  int fireTime; // for timer for when to send a message to core router

  bool mRadioBusy = FALSE;  // lock to prevent race conditions

  // create host and destination tables
  void createTables() {
    mHostLimit = (call Random.rand32()) % (MAX_HOST_NUM + 1 - MIN_HOST_NUM) + MIN_HOST_NUM; // get random host limit

    // fill in host table
    for (i = 0; i < mHostLimit; i++) {
      mHostTable[i] = TOS_NODE_ID * ROUTER_MASK + i + 1;
    }

    mDestLimit = (MAX_ROUTER_NUM-1) * mHostLimit; // get destination limit

    // fill in destination table
    for (i = 1; i < MAX_ROUTER_NUM; i++) {
      int eRouter = TOS_NODE_ID+i; // include edge routers other than this one
      eRouter = (eRouter <= MAX_ROUTER_NUM) ? eRouter : eRouter / MAX_ROUTER_NUM;
      for (j = 0; j < mHostLimit; j++) {
	mDestTable[((i-1)*mHostLimit)+j] = eRouter * ROUTER_MASK + j + 1;
      }
    }
  }

  // when edge router boots
  event void Boot.booted() {
    createTables(); // get randomly generated host and destination tables

    // makes sure indicating leds are off at start
    call Leds.led1Off();
    call Leds.led2Off();
     
    call AMControl.start();

    // get random fire time to send messages to core router
    fireTime = ((call Random.rand32()) % (MAX_FIRE_TIME + 1 - MIN_FIRE_TIME) + MIN_FIRE_TIME) * MILLISEC;
    call Timer0.startPeriodic(fireTime);
  }

  // get a random host from host table
  nx_int16_t getHostNum() {
    return mHostTable[(call Random.rand32()) % mHostLimit];
  }

  // get a random edge router/host pair from destionation table
  nx_int16_t getDestNum() {
    return mDestTable[(call Random.rand32()) % mDestLimit];
  };

  // generate a random payload to send
  nx_int16_t getPayload() {
    return call Random.rand16();
  };

  // send a message to core router every time timer fires
  event void Timer0.fired() {
    // only send messsage when radio is not busy
    if (mRadioBusy == FALSE) {
      EdgeCoreMsg_t *msg = call Packet.getPayload(&mPacket, sizeof(EdgeCoreMsg_t));
      msg->From = getHostNum(); // mark as a host from this edge router
      msg->Bcast = CORE_ROUTER_ID; // send to core routre

      // create the msg part of the message that encapsulates the true To destination and message
      mPayload.From = msg->From; // message source
      mPayload.Bcast = getDestNum(); // message destination
      mPayload.Msg = getPayload(); // true message/payload
      msg->Msg = mPayload; // hold true message for true destination
      
      // sends to message to core router
      if (call AMSend.send(CORE_ROUTER_ID, &mPacket, sizeof(EdgeCoreMsg_t)) == SUCCESS) {
        mRadioBusy = TRUE; // set the lock
        call Leds.led1Toggle(); // indicate message to core router sent
      }
    }
  }

  // after sending the packet over the radio
  event void AMSend.sendDone(message_t *msg, error_t error) {
    if(msg == &mPacket) {
      mRadioBusy = FALSE; // release the lock
    }
  }

  // make sure that AMControl starts properly
  event void AMControl.startDone(error_t error) {
    if (error != SUCCESS) {
      call AMControl.start(); // retry start
    }
  }

  // don't need to do anything here
  event void AMControl.stopDone(error_t error) {
  }

  // receive the acknowledgement back from the core router
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    // make sure that the recieved packet is from the core router
    if (len == sizeof(CoreEdgeMsg_t)) {
      CoreEdgeMsg_t *incomingMsg = (CoreEdgeMsg_t *) payload;
      // make sure that its the intended router
      if (incomingMsg->Bcast / ROUTER_MASK == TOS_NODE_ID) {
        call Leds.led2Toggle(); // indicate acknowledgement receieved
      }
    }
    return msg;
  }
}
