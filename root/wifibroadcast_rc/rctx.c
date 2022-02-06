// rctx by Rodizio
// Based on JS2Serial by Oliver Mueller and wbc all-in-one tx by Anemostec.
// Thanks to dino_de for the Joystick switches and mavlink code
// Licensed under GPL2
#include <stdlib.h>
#include <stdio.h>
#include <sys/resource.h>
#include <SDL/SDL.h>
#include <termios.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <netpacket/packet.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <arpa/inet.h>
#include <string.h>
#include <getopt.h>
#include "lib.h"

#include "/tmp/rctx.h"

#define UPDATE_INTERVAL 2000 // read Joystick every 2 ms or 500x per second
#define JOY_CHECK_NTH_TIME 400 // check if joystick disconnected every 400th time or 200ms or 5x per second
#define JOYSTICK_N 0
#define JOY_DEV "/sys/class/input/js0"

#ifdef JSSWITCHES  // 1 byte more for channels 9 - 16 as switches

	static uint16_t *rcData = NULL;

	uint16_t *rc_channels_memory_open(void) {

		int fd = shm_open("/wifibroadcast_rc_channels", O_CREAT | O_RDWR, S_IRUSR | S_IWUSR);

		if(fd < 0) {
			fprintf(stderr,"rc shm_open\n");
			exit(1);
		}

		if (ftruncate(fd, 9 * sizeof(uint16_t)) == -1) {
			fprintf(stderr,"rc ftruncate\n");
			exit(1);
		}

		void *retval = mmap(NULL, 9 * sizeof(uint16_t), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
		if (retval == MAP_FAILED) {
			fprintf(stderr,"rc mmap\n");
			exit(1);
		}

	return (uint16_t *)retval;
	}
#else
	static uint16_t rcData[8]; // interval [1000;2000]
#endif

static SDL_Joystick *js;
char *ifname = NULL;
int flagHelp = 0;
int sock = 0;
int socks[5];
int type[5];
int num_interfaces = 0;

struct framedata_s {
    // 88 bits of data (11 bits per channel * 8 channels) = 11 bytes
    uint8_t rt1;
    uint8_t rt2;
    uint8_t rt3;
    uint8_t rt4;
    uint8_t rt5;
    uint8_t rt6;
    uint8_t rt7;
    uint8_t rt8;

    uint8_t rt9;
    uint8_t rt10;
    uint8_t rt11;
    uint8_t rt12;

    uint8_t fc1;
    uint8_t fc2;
    uint8_t dur1;
    uint8_t dur2;
	
    uint8_t mac1_1; // Port
	
    uint8_t seqnumber;

    unsigned int chan1 : 11;
    unsigned int chan2 : 11;
    unsigned int chan3 : 11;
    unsigned int chan4 : 11;
    unsigned int chan5 : 11;
    unsigned int chan6 : 11;
    unsigned int chan7 : 11;
    unsigned int chan8 : 11;
#ifdef JSSWITCHES
    unsigned int switches : JSSWITCHES; // 8 or 16 bits for rc channels 9 - 16/24  as switches
#endif
} __attribute__ ((__packed__));

struct framedata_s framedatas;

struct framedata_n {
    // 88 bits of data (11 bits per channel * 8 channels) = 11 bytes
    uint8_t rt1;
    uint8_t rt2;
    uint8_t rt3;
    uint8_t rt4;
    uint8_t rt5;
    uint8_t rt6;
    uint8_t rt7;
    uint8_t rt8;

    uint8_t rt9;
    uint8_t rt10;
    uint8_t rt11;
    uint8_t rt12;
	uint8_t rt13;

    uint8_t fc1;
    uint8_t fc2;
    uint8_t dur1;
    uint8_t dur2;
	
	uint8_t mac1_1; // Port
    uint8_t mac1_2;
    uint8_t mac1_3;
    uint8_t mac1_4;
    uint8_t mac1_5;
    uint8_t mac1_6;

    uint8_t mac2_1;
    uint8_t mac2_2;
    uint8_t mac2_3;
    uint8_t mac2_4;
    uint8_t mac2_5;
    uint8_t mac2_6;

    uint8_t mac3_1;
    uint8_t mac3_2;
    uint8_t mac3_3;
    uint8_t mac3_4;
    uint8_t mac3_5;
    uint8_t mac3_6;

    uint8_t ieeeseq1;
    uint8_t ieeeseq2;

    uint8_t seqnumber;

    unsigned int chan1 : 11;
    unsigned int chan2 : 11;
    unsigned int chan3 : 11;
    unsigned int chan4 : 11;
    unsigned int chan5 : 11;
    unsigned int chan6 : 11;
    unsigned int chan7 : 11;
    unsigned int chan8 : 11;
#ifdef JSSWITCHES
    unsigned int switches : JSSWITCHES; // 8 or 16 bits for rc channels 9 - 16/24  as switches
#endif
} __attribute__ ((__packed__));

struct framedata_n framedatan;


void usage(void)
{
    printf(
        "rctx by Rodizio. Based on JS2Serial by Oliver Mueller and wbc all-in-one tx by Anemostec. GPL2\n"
        "\n"
        "Usage: rctx [options] <interfaces>\n"
        "Options:\n"
		"-p <port>   Port. Default = 3\n"
		"-d <stbc>   stbc ldpc enable (Realtek only)\n"
        "Example:\n"
        "  rctx -p 3 -d 0 wlan0\n"
        "\n");
    exit(1);
}

static int open_sock (char *ifname) {
    struct sockaddr_ll ll_addr;
    struct ifreq ifr;

    sock = socket (AF_PACKET, SOCK_RAW, 0);
    if (sock == -1) {
	fprintf(stderr, "Error:\tSocket failed\n");
	exit(1);
    }

    ll_addr.sll_family = AF_PACKET;
    ll_addr.sll_protocol = 0;
    ll_addr.sll_halen = ETH_ALEN;

    strncpy(ifr.ifr_name, ifname, IFNAMSIZ);

    if (ioctl(sock, SIOCGIFINDEX, &ifr) < 0) {
	fprintf(stderr, "Error:\tioctl(SIOCGIFINDEX) failed\n");
	exit(1);
    }

    ll_addr.sll_ifindex = ifr.ifr_ifindex;

    if (ioctl(sock, SIOCGIFHWADDR, &ifr) < 0) {
	fprintf(stderr, "Error:\tioctl(SIOCGIFHWADDR) failed\n");
	exit(1);
    }

    memcpy(ll_addr.sll_addr, ifr.ifr_hwaddr.sa_data, ETH_ALEN);

    if (bind (sock, (struct sockaddr *)&ll_addr, sizeof(ll_addr)) == -1) {
	fprintf(stderr, "Error:\tbind failed\n");
	close(sock);
	exit(1);
    }

    if (sock == -1 ) {
        fprintf(stderr,
        "Error:\tCannot open socket\n"
        "Info:\tMust be root with an 802.11 card with RFMON enabled\n");
        exit(1);
    }

    return sock;
}


int16_t parsetoMultiWii(Sint16 value) {
	return (int16_t)(((((double)value)+32768.0)/65.536)+1000);
}


void readAxis(SDL_Event *event) {
	SDL_Event myevent = (SDL_Event)*event;
	switch(myevent.jaxis.axis) {
		case ROLL_AXIS:
				rcData[0]=parsetoMultiWii(myevent.jaxis.value);
			break;
		case PITCH_AXIS:
				rcData[1]=parsetoMultiWii(myevent.jaxis.value);
			break;
		case THROTTLE_AXIS:
				rcData[2]=parsetoMultiWii(myevent.jaxis.value);
			break;
		case YAW_AXIS:
				rcData[3]=parsetoMultiWii(myevent.jaxis.value);
			break;
		case AUX1_AXIS:
				rcData[4]=parsetoMultiWii(myevent.jaxis.value);
			break;
		case AUX2_AXIS:
				rcData[5]=parsetoMultiWii(myevent.jaxis.value);
			break;
		case AUX3_AXIS:
				rcData[6]=parsetoMultiWii(myevent.jaxis.value);
			break;
		case AUX4_AXIS:
				rcData[7]=parsetoMultiWii(myevent.jaxis.value);
			break;
		default:
			break; //do nothing
	}
}


static int eventloop_joystick (void) {
  SDL_Event event;
  while (SDL_PollEvent (&event)) {
    switch (event.type) {
		case SDL_JOYAXISMOTION:
			//printf ("Joystick %d, Axis %d moved to %d\n", event.jaxis.which, event.jaxis.axis, event.jaxis.value);
			readAxis(&event);
			return 2;
			break;
#ifdef	JSSWITCHES  // channels 9 - 16 as switches
		case SDL_JOYBUTTONDOWN:
			if (event.jbutton.button < JSSWITCHES) { // newer Taranis software can send 24 buttons - we use 16
				rcData[8] |= 1 << event.jbutton.button;
			}
			return 5;
			break;
		case SDL_JOYBUTTONUP:
			if (event.jbutton.button < JSSWITCHES) {
				rcData[8] &= ~(1 << event.jbutton.button);
			}
			return 4;
			break;
#endif
		case SDL_QUIT:
			return 0;
			break;
    }
    usleep(100);
  }
  return 1;
}

void sendRC(unsigned char seqno, telemetry_data_t *td) {
    uint8_t i;
    uint8_t z;

    framedatas.seqnumber = seqno;
    framedatas.chan1 = rcData[0];
    framedatas.chan2 = rcData[1];
    framedatas.chan3 = rcData[2];
    framedatas.chan4 = rcData[3];
    framedatas.chan5 = rcData[4];
    framedatas.chan6 = rcData[5];
    framedatas.chan7 = rcData[6];
    framedatas.chan8 = rcData[7];
#ifdef JSSWITCHES
	framedatas.switches = rcData[8];	/// channels 9 - 24 as switches
//	printf ("rcdata0:%x\t",rcData[8]);
#endif
//  printf ("rcdata0:%d\n",rcData[0]);

    framedatan.seqnumber = seqno;
    framedatan.chan1 = rcData[0];
    framedatan.chan2 = rcData[1];
    framedatan.chan3 = rcData[2];
    framedatan.chan4 = rcData[3];
    framedatan.chan5 = rcData[4];
    framedatan.chan6 = rcData[5];
    framedatan.chan7 = rcData[6];
    framedatan.chan8 = rcData[7];
#ifdef JSSWITCHES
	framedatan.switches = rcData[8];	/// channels 9 - 24 as switches
//	printf ("rcdata0:%x\t",rcData[8]);
#endif
//  printf ("rcdata0:%d\n",rcData[0]);

    int best_adapter = 0;
    if(td->rx_status != NULL) {
	int j = 0;
	int best_dbm = -1000;

        if (num_interfaces > 1) {
// find out which card has best signal and ignore ralink (type[j]== 0) ones
	    for(j=0; j<num_interfaces; ++j) {
	    if ((best_dbm < td->rx_status->adapter[j].current_signal_dbm)&&(type[j] != 0)) {
		best_dbm = td->rx_status->adapter[j].current_signal_dbm;
		best_adapter = j;
		//printf ("best_adapter: :%d\n",best_adapter);
	    }
	    }
	    }
	    if (type[best_adapter] == 2) {
//	printf ("bestadapter: %d (%d dbm)\n",best_adapter, best_dbm);
	    if (write(socks[best_adapter], &framedatan, sizeof(framedatan)) < 0 ) fprintf(stderr, "!");	/// framedata_n = 28 or 29 bytes
	    } else {
	    if (write(socks[best_adapter], &framedatas, sizeof(framedatas)) < 0 ) fprintf(stderr, "!");	/// framedata_s = 28 or 29 bytes
	    }
    } else {
	printf ("ERROR: Could not open rx status memory!");
    }
}



wifibroadcast_rx_status_t *telemetry_wbc_status_memory_open(void) {
    int fd = 0;
    int sharedmem = 0;

    while(sharedmem == 0) {
        fd = shm_open("/wifibroadcast_rx_status_0", O_RDONLY, S_IRUSR | S_IWUSR);
	    if(fd < 0) {
		fprintf(stderr, "Could not open wifibroadcast rx status - will try again ...\n");
	    } else {
		sharedmem = 1;
	    }
	    usleep(100000);
    }

//        if (ftruncate(fd, sizeof(wifibroadcast_rx_status_t)) == -1) {
//                perror("ftruncate");
//                exit(1);
//        }

        void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t), PROT_READ, MAP_SHARED, fd, 0);
        if (retval == MAP_FAILED) {
                perror("mmap");
                exit(1);
        }

        return (wifibroadcast_rx_status_t*)retval;

return 0;
}


void telemetry_init(telemetry_data_t *td) {
    td->rx_status = telemetry_wbc_status_memory_open();
}


int main (int argc, char *argv[]) {
    int done = 1;
    int joy_connected = 0;
    int joy = 1;
    int update_nth_time = 0;
	int param_port = 3;
	int stbc_ldpc = 0;
	
	char line[100], path[100];
    FILE* procfile;

    while (1) {
	int nOptionIndex;
	static const struct option optiona[] = {
	    { "help", no_argument, &flagHelp, 1 },
	    { 0, 0, 0, 0 }
	};
	int c = getopt_long(argc, argv, "h:p:d:", optiona, &nOptionIndex);
	if (c == -1)
	    break;
	switch (c) {
	case 0: // long option
	    break;
	case 'h': // help
	    usage();
	    break;
	case 'p': // port
		param_port = atoi(optarg);
		break;
    case 'd': // stbc ldpc enable
		stbc_ldpc = atoi(optarg);
    	break;
	default:
	    fprintf(stderr, "unknown switch %c\n", c);
	    usage();
	}
    }

    if (optind >= argc) usage();
	
	int x = optind;

    while(x < argc && num_interfaces < 5) {
    	snprintf(path, 45, "/sys/class/net/%s/device/uevent", argv[x]);
        procfile = fopen(path, "r");
        if(!procfile) {fprintf(stderr,"ERROR: opening %s failed!\n", path); return 0;}
        fgets(line, 100, procfile); // read the first line
        fgets(line, 100, procfile); // read the 2nd line
	if (strncmp(line, "DRIVER=ath9k_htc", 16) == 0 || 
        (
         strncmp(line, "DRIVER=8812au",    13) == 0 || 
         strncmp(line, "DRIVER=8814au",    13) == 0 || 
         strncmp(line, "DRIVER=rtl8812au", 16) == 0 || 
         strncmp(line, "DRIVER=rtl8814au", 16) == 0 || 
         strncmp(line, "DRIVER=rtl88xxau", 16) == 0
        )) {   
		if (strncmp(line, "DRIVER=ath9k_htc", 16) == 0) {
			  fprintf(stderr, "rctx: Atheros card detected\n");
	          type[num_interfaces] = 1;
		} else {
			  fprintf(stderr, "rctx: Realtek card detected\n");
			  type[num_interfaces] = 2;
		}
    } else { // ralink or mediatek
              fprintf(stderr, "rctx: Ralink card detected\n");
	          type[num_interfaces] = 0;
    }
	socks[num_interfaces] = open_sock(argv[x]);
        ++num_interfaces;
	    ++x;
        fclose(procfile);
    usleep(20000); // wait a bit between configuring interfaces to reduce Atheros and Pi USB flakiness
    }

	framedatan.rt1 = 0; // <-- radiotap version      (0x00)
	framedatan.rt2 = 0; // <-- radiotap version      (0x00)

	framedatan.rt3 = 13; // <- radiotap header length(0x0d)
	framedatan.rt4 = 0; // <- radiotap header length (0x00)

	framedatan.rt5 = 0; // <-- radiotap present flags(0x00)
	framedatan.rt6 = 128; // <-- RADIOTAP_TX_FLAGS + (0x80)
	framedatan.rt7 = 8; // <--  RADIOTAP_MCS         (0x08)
	framedatan.rt8 = 0; //                           (0x00)

	framedatan.rt9 = 8; // <-- RADIOTAP_F_TX_NOACK   (0x08)
	framedatan.rt10 = 0; //                          (0x00)
	framedatan.rt11 = 55; // <-- bitmap              (0x37)
	if (stbc_ldpc == 1) {
	    framedatan.rt12 = 48; // <-- flags               (0x30)
	} else {
		framedatan.rt12 = 0; // <-- flags               (0x00)
	}	
	framedatan.rt13 = 0; // <-- mcs_index            (0x00)

	framedatan.fc1 = 180; // <-- frame control field (0xb4)
	framedatan.fc2 = 1; // <-- frame control field (0x01)
	framedatan.dur1 = 0; // <-- duration
	framedatan.dur2 = 0; // <-- duration
	
	framedatan.mac1_1 = (param_port * 2) + 1;
	framedatan.mac1_2 = 0;
	framedatan.mac1_3 = 0;
	framedatan.mac1_4 = 0;
	framedatan.mac1_5 = 0;
	framedatan.mac1_6 = 0;

	framedatan.mac2_1 = 0;
	framedatan.mac2_2 = 0;
	framedatan.mac2_3 = 0;
	framedatan.mac2_4 = 0;
	framedatan.mac2_5 = 0;
	framedatan.mac2_6 = 0;

	framedatan.mac3_1 = 0;
	framedatan.mac3_2 = 0;
	framedatan.mac3_3 = 0;
	framedatan.mac3_4 = 0;
	framedatan.mac3_5 = 0;
	framedatan.mac3_6 = 0;

	framedatan.ieeeseq1 = 0;
	framedatan.ieeeseq2 = 0;
	
	
	framedatas.rt1 = 0; // <-- radiotap version
	framedatas.rt2 = 0; // <-- radiotap version

	framedatas.rt3 = 12; // <- radiotap header length
	framedatas.rt4 = 0; // <- radiotap header length

	framedatas.rt5 = 4; // <-- radiotap present flags
	framedatas.rt6 = 128; // <-- radiotap present flags
	framedatas.rt7 = 0; // <-- radiotap present flags
	framedatas.rt8 = 0; // <-- radiotap present flags

	framedatas.rt9 = 24; // <-- radiotap rate
	framedatas.rt10 = 0; // <-- radiotap stuff
	framedatas.rt11 = 0; // <-- radiotap stuff
	framedatas.rt12 = 0; // <-- radiotap stuff

	framedatas.fc1 = 180; // <-- frame control field (0xb4)
	framedatas.fc2 = 191; // <-- frame control field (0xbf)
	framedatas.dur1 = 0; // <-- duration
	framedatas.dur2 = 0; // <-- duration
	
	framedatas.mac1_1 = (param_port * 2) + 1;
	

	fprintf(stderr, "Waiting for joystick ...");
	while (joy) {
	    joy_connected=access(JOY_DEV, F_OK);
	    fprintf(stderr, ".");
	    if (joy_connected == 0) {
		fprintf(stderr, "connected!\n");
		joy=0;
	    }
	    usleep(100000);
	}

	// we need to prefill channels since we have no values for them as
	// long as the corresponding axis has not been moved yet
#ifdef	JSSWITCHES
	rcData = rc_channels_memory_open();
	rcData[8]=0;		/// switches
#endif
	rcData[0]=AXIS0_INITIAL;
	rcData[1]=AXIS1_INITIAL;
	rcData[2]=AXIS2_INITIAL;
	rcData[3]=AXIS3_INITIAL;
	rcData[4]=AXIS4_INITIAL;
	rcData[5]=AXIS5_INITIAL;
	rcData[6]=AXIS6_INITIAL;
	rcData[7]=AXIS7_INITIAL;

	if (SDL_Init (SDL_INIT_JOYSTICK | SDL_INIT_VIDEO) != 0)
	{
		printf ("ERROR: %s\n", SDL_GetError ());
		return EXIT_FAILURE;
	}
	atexit (SDL_Quit);
	js = SDL_JoystickOpen (JOYSTICK_N);
	if (js == NULL)
	{
		printf("Couldn't open desired Joystick: %s\n",SDL_GetError());
		done=0;
	} else {
		printf ("\tName:       %s\n", SDL_JoystickName(JOYSTICK_N));
		printf ("\tAxis:       %i\n", SDL_JoystickNumAxes(js));
		printf ("\tTrackballs: %i\n", SDL_JoystickNumBalls(js));
		printf ("\tButtons:   %i\n",SDL_JoystickNumButtons(js));
		printf ("\tHats: %i\n",SDL_JoystickNumHats(js)); 
	}

	// init RSSI shared memory
	telemetry_data_t td;
	telemetry_init(&td);

	int counter = 0;
	int seqno = 0;
	int k = 0;
	while (done) {
		done = eventloop_joystick();
//		fprintf(stderr, "eventloop_joystick\n");
		if (counter % UPDATE_NTH_TIME == 0) {
//		    fprintf(stderr, "SendRC\n");
		    for(k=0; k < TRANSMISSIONS; ++k) {
			sendRC(seqno,&td);
			usleep(2000); // wait 2ms between sending multiple frames to lower collision probability
		    }
		    seqno++;
		}
		if (counter % JOY_CHECK_NTH_TIME == 0) {
		    joy_connected=access(JOY_DEV, F_OK);
		    if (joy_connected != 0) {
			fprintf(stderr, "joystick disconnected, exiting\n");
			done=0;
		    }
		}
		usleep(UPDATE_INTERVAL);
		counter++;
	}
	SDL_JoystickClose (js);
	return EXIT_SUCCESS;
}
