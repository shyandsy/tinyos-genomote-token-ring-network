#include "TokenRing.h"

/*
 * The AM address of a node can be set at installation time, using the make install.n or make reinstall.n commands. 
 * It can be changed at runtime using the ActiveMessageAddressC component (see below).
 */
module TokenRingC {

	uses {
		interface Boot;
		interface Leds;
		interface Timer<TMilli> as TimerWorker;
		interface AMSend;
		interface Receive;
		interface SplitControl as AMControl;
	}
}
implementation {
	bool sending;	// is sending now?
	bool holdToken;	// does it hold the token now? 

	const uint8_t NODE_QUANTITY = 3; // number of node in the network 
	
	enum { 
		TIMER_PERIOD_MILLI = 250,
		
		ACCEL_INTERVAL = 256, 	/* Checking interval */
		ACCEL_PERIOD = 10000, 	/* uS -> 100Hz */
		ACCEL_NSAMPLES = 10, 	/* 10 samples * 100Hz -> 0.1s */
		ACCEL_VARIANCE = 4		/* Determined experimentally */
	};

	/* declare functions */
	void Led0On();
	void Led1On();
	void Led2On();
	void Led0Off();
	void Led1Off();
	void Led2Off();
	void passToken();

	event void Boot.booted() {
		// initialize sending state
		sending = FALSE;

		// initialize the led light: 0 on, 1 and 2 off
		Led0On();
		Led1Off();
		Led2Off();
		
		// start communication
		call AMControl.start();
	}
	
	// start radio
	event void AMControl.startDone(error_t error){
		if (error == SUCCESS) {
			//start token ring network
			if(TOS_NODE_ID == 0) {		// light up if current is the node 0
	
				holdToken = TRUE;
	
				// light 1 ON
				Led1On();
	
				//set timer for 2000ms
				call TimerWorker.startOneShot(2000);
	
			}
			else 						// wait data when 
			{
				holdToken = FALSE;
	
				//wait the token
			}
    	}
		else
		{
      		call AMControl.start(); // try again
    	}
	}
	
	// stop radio
	event void AMControl.stopDone(error_t error){
		// TODO Auto-generated method stub
	}

	//finish send operation
	event void AMSend.sendDone(message_t * msg, error_t error) {
		if(error == SUCCESS){
			sending = FALSE;
			
			// light 1 OFF
			Led1Off();
		}else{
			
			//resend
			passToken();
			
		}
	}

	event void TimerWorker.fired() {
		//pass the token to next device and light off
		passToken();
	}

	event message_t * Receive.receive(message_t * msg, void * payload,
			uint8_t len) {
		if (len >= sizeof(data_t)) // Check the packet seems valid
		{ 
			// Read settings by casting payload to data_t, reset check interval
			data_t *data = payload;
			if(data->opcode == 0 && data->length == 0){
				
				//hold token
				holdToken = TRUE;

				// light 1 ON
				Led1On();
			
				call TimerWorker.startOneShot(2000);
			}
		}
		
		return msg;
	}

	
	
	void Led0On()
	{
		call Leds.led0On();
	}

	void Led1On() {
		call Leds.led1On();
	}

	void Led2On() {
		call Leds.led2On();
	}

	void Led0Off() {
		call Leds.led0Off();
	}

	void Led1Off() {
		call Leds.led1Off();
	}

	void Led2Off() {
		call Leds.led2Off();
	}

	/*pass token to the next node*/
	void passToken() {
		message_t msg;
		data_t * payload;
		uint8_t next;

		payload = call AMSend.getPayload(&msg, sizeof(data_t));

		next = (uint8_t)((TOS_NODE_ID + 1) % NODE_QUANTITY);

		if(payload && ! sending) {
			payload->opcode = 0; //token
			payload->length = 0;

			if(call AMSend.send(next, &msg, sizeof(data_t)) == SUCCESS) {
				sending = TRUE;
			}
		}
	}
}