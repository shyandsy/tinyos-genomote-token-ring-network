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
  bool mRadioBusy = FALSE;

  message_t mPacket;

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMSend.sendDone(message_t *msg, error_t error) {
    if(msg == &mPacket) {
      mRadioBusy = FALSE;
      call Leds.led1Off();
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
    if (len == sizeof(EdgeCoreMsg_t)) {
      EdgeCoreMsg_t *incomingMsg = (EdgeCoreMsg_t *) payload;
      printf("Message received... ");
      printf("E%dH%d ", incomingMsg->From / ROUTER_MASK, incomingMsg->From % ROUTER_MASK);
      printf("E%dH%d ", incomingMsg->Bcast / ROUTER_MASK, incomingMsg->Bcast % ROUTER_MASK);
      printf("E%dH%d+", (incomingMsg->Msg).From / ROUTER_MASK, (incomingMsg->Msg).From % ROUTER_MASK);
      printf("E%dH%d+", (incomingMsg->Msg).Bcast / ROUTER_MASK, (incomingMsg->Msg).Bcast % ROUTER_MASK);
      printf("%d\n", (incomingMsg->Msg).Msg);
      printfflush();
      call Leds.led2Toggle();

      if (mRadioBusy == FALSE) {
        CoreEdgeMsg_t *destPayload = call Packet.getPayload(&mPacket, sizeof(CoreEdgeMsg_t));
        destPayload->From = TOS_NODE_ID;
        destPayload->Bcast = incomingMsg->From;
        destPayload->Msg = 200;
      
        if (call AMSend.send(incomingMsg->From / ROUTER_MASK, &mPacket, sizeof(CoreEdgeMsg_t)) == SUCCESS) {
          mRadioBusy = TRUE;
          call Leds.led1Toggle();
        }
      }
    }
    return msg;
  }
}
