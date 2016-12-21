configuration EdgeRouterAppC {
}
implementation {
  components EdgeRouterC;

  components MainC;
  components LedsC;
  components RandomC;
  components new TimerMilliC() as Timer0;

  EdgeRouterC -> MainC.Boot;
  EdgeRouterC.Timer0 -> Timer0;
  EdgeRouterC.Leds -> LedsC;
  EdgeRouterC.Random -> RandomC;

  components ActiveMessageC;
  components new AMSenderC(AM_RADIO);
  components new AMReceiverC(AM_RADIO);

  EdgeRouterC.Packet -> AMSenderC;
  EdgeRouterC.AMPacket -> AMSenderC;
  EdgeRouterC.AMSend -> AMSenderC;
  EdgeRouterC.AMControl -> ActiveMessageC;
  EdgeRouterC.Receive -> AMReceiverC;
}
