configuration CoreRouterAppC {
}
implementation {
  components CoreRouterC;

  components MainC;
  components LedsC;

  CoreRouterC -> MainC.Boot;
  CoreRouterC.Leds -> LedsC;

  components PrintfC;

  components ActiveMessageC;
  components new AMSenderC(AM_RADIO);
  components new AMReceiverC(AM_RADIO);

  CoreRouterC.Packet -> AMSenderC;
  CoreRouterC.AMPacket -> AMSenderC;
  CoreRouterC.AMSend -> AMSenderC;
  CoreRouterC.AMControl -> ActiveMessageC;
  CoreRouterC.Receive -> AMReceiverC;
}
