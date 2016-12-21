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
    if (len == sizeof(RouterMsg_t)) {
      RouterMsg_t *incomingMsg = (RouterMsg_t *) payload;
      printf("Message received... ");
      printf("E%dH%d ", incomingMsg->From / 100, incomingMsg->From % 100);
      printf("E%dH%d ", incomingMsg->Bcast / 100, incomingMsg->Bcast % 100);
      printf("E%dH%d\n", incomingMsg->Msg / 100, incomingMsg->Msg % 100);
      printfflush();
      call Leds.led2Toggle();

      if (mRadioBusy == FALSE) {
        RouterMsg_t *destPayload = call Packet.getPayload(&mPacket, sizeof(RouterMsg_t));
        destPayload->From = TOS_NODE_ID;
        destPayload->Bcast = incomingMsg->From;
        destPayload->Msg = 200;
      
        if (call AMSend.send(incomingMsg->From / 100, &mPacket, sizeof(RouterMsg_t)) == SUCCESS) {
          mRadioBusy = TRUE;
          call Leds.led1Toggle();
        }
      }
    }
    return msg;
  }
}
