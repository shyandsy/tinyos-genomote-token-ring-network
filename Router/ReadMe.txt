1.	The structure of the program:
    Code for the core router is under the CoreRouter directory
    Code for the edge router is under the EdgeRouter directory

    For CoreRouter part:
    1)	Router.h
            The header file which include the data structure we use.

            The Core -> Edge payload data structure was defined in this file, which is shown below 
            typedef nx_struct CoreEdgeMsg {
              nx_int16_t From;
              nx_int16_t Bcast;
              nx_int16_t Msg;
            } CoreEdgeMsg_t;

            The Edge -> Core payload data structure was defined in this file, which is shown below
            typedef nx_struct EdgeCoreMsg {
              nx_int16_t From;
              nx_int16_t Bcast;
              CoreEdgeMsg_t Msg;
            } EdgeCoreMsg_t;

            For matching sender and receiver AM type 
            enum {
              AM_RADIO = 8
            }

    2)	CoreRouterAppc.nc
            The configuration of CoreRouter

    3)	CoreRouterC.nc
            1.	Receives message from edge router
            2.	Prints messages. Toggles Led 2 after receive and read
            3.	Send ACK back to edge router. Toggles  Led 1 after send

    4)	Makefile – Compiles the CoreRouter Part


For EdgeRouter part:
    1)	Router.h
            Same as the Core Router router.h
            
    2)	EdgeRouterAppc.nc
            The configuration of EdgeRouter

    3)	EdgeRouterC.nc
            1.	Create host table filled with entries of format EH
                    E - between 1 to 4, the number is the edge router ID
                    H - between 1 to host limit which is randomly generated between 10 to 99
            2.	Create destination table filled with entries of format EH
                    E - between 1 to 4, the number is NOT the edge router ID
                    H - between 1 to host limit which is randomly generated between 10 to 99 (same as H for host table )
            3.	Generate random timer for sends
            4.	Pick random host from host table for From field of message
                Choose pre-defined CoreRouter ID for Bcast field of message
                For Msg field:
                    From: Same as previous From field above.
                    Bcast: Random Router/host pair from destination table
                    Msg: Random 16-bit number

                Toggle Led 1 after send
            5.	Receive ACKs from core Router. Toggle Led 2 after receive

    4)	Makefile – Compiles the EdgeRouter Part

2.	How to compile the code
    To compile/install core router:
        Make sure to be in the CoreRouter Directory & a genomote is detected by the PC
        Type:
            make genomote install.550 master

        To compile/install edge router:
        Make sure to be in the EdgeRouter Directory & a genomote is detected by the PC
        Type:
            make genomote install.1 master (For 1st edge router)
            make genomote install.2 master (For 2nd edge router)
            make genomote install.3 master (For 3rd edge router)
            make genomote install.4 master (For 4th edge router)

3.  To test system:
    Make sure all edge router are in the RUN position& the core router is in the PRO position and connected to the PC
    To read messages:
        Type: java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSBX:57600
                For the USBX, use port # associated with Core Router

    An example of what will be displayed by PrintfClient:
        Message received… E1H37 E5H50 E1H37+E3H52+9497
        
        What it all means:
            E1H37 – the source (Edge router)
            E5H50 – the destination (Core router)
            E1H37+E3H52+9497 – the payload
                E1H37 – the source (Edge router)
                E3H52 – the true destination (Edge router)
                9497 – the true payload
	


