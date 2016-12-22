#include "Router.h"
#include "printf.h"

module CoreRouterC {
  uses { // GENERAL INTERFACE
    interface Boot;
    interface Leds;
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
  bool mRadioBusy = FALSE; // lock to prevent race conditions

  message_t mPacket; // packet to send acknowledgement

  // when the core router boots
  event void Boot.booted() {
    // makes sure indicating leds are off at start
    call Leds.led1Off();
    call Leds.led2Off();

    call AMControl.start();
  }

  // after sending the packet over the radio
  event void AMSend.sendDone(message_t *msg, error_t error) {
    if(msg == &mPacket) {
      mRadioBusy = FALSE; // release lock
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

  // recieves message from edge router then sends back acknowledgement
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {

    // make sure that the recieved packet is from the edge router
    if (len == sizeof(EdgeCoreMsg_t)) {
      EdgeCoreMsg_t *incomingMsg = (EdgeCoreMsg_t *) payload;
      // print out contents of edge router message for PrintfClient to display
      printf("Message received... ");
      printf("E%dH%d ", incomingMsg->From / ROUTER_MASK, incomingMsg->From % ROUTER_MASK); // From
      printf("E%dH%d ", incomingMsg->Bcast / ROUTER_MASK, incomingMsg->Bcast % ROUTER_MASK); // To
      printf("E%dH%d+", (incomingMsg->Msg).From / ROUTER_MASK, (incomingMsg->Msg).From % ROUTER_MASK); // Msg - From
      printf("E%dH%d+", (incomingMsg->Msg).Bcast / ROUTER_MASK, (incomingMsg->Msg).Bcast % ROUTER_MASK); // Msg - To
      printf("%d\n", (incomingMsg->Msg).Msg); // Msg - Msg
      printfflush();
      call Leds.led2Toggle(); // indicate edge router message recieved

      // send acknowlegement back only when radio is not busy
      if (mRadioBusy == FALSE) {
        CoreEdgeMsg_t *destPayload = call Packet.getPayload(&mPacket, sizeof(CoreEdgeMsg_t));
        destPayload->From = TOS_NODE_ID; // this node
        destPayload->Bcast = incomingMsg->From; // sender 
        destPayload->Msg = 200; // 200 signals an okay
      
        // sends the acknowledgement
        if (call AMSend.send(incomingMsg->From / ROUTER_MASK, &mPacket, sizeof(CoreEdgeMsg_t)) == SUCCESS) {
          mRadioBusy = TRUE; // set the lock
          call Leds.led1Toggle(); // indicate acknowledgement sent
        }
      }
    }
    return msg;
  }
}
