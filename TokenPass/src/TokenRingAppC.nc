configuration TokenRingAppC{
}
implementation{
	components TokenRingC as App;
	components MainC;
	components LedsC;
	components new TimerMilliC() as WorkerTimer;
	components new AMSenderC(0) as AMSender;
	components new AMReceiverC(0) as AMReceiver;
	components ActiveMessageC;
	
	App.Boot -> MainC;
	App.Leds -> LedsC;	
	App.TimerWorker -> WorkerTimer;
	App.AMSend -> AMSender;
	App.Receive -> AMReceiver;
	App.AMControl -> ActiveMessageC;
}