// check_alive by Rodizio. Checks for incoming wifibroadcast packets. GPL2 licensed.
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <resolv.h>
#include <string.h>
#include <utime.h>
#include <unistd.h>
#include <getopt.h>
#include <pcap.h>
#include <endian.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "lib.h"

#include <wiringPi.h>

wifibroadcast_rx_status_t *status_memory_open(void) {
	int fd;

	for(;;) {
		fd = shm_open("/wifibroadcast_rx_status_0", O_RDWR, S_IRUSR | S_IWUSR);
		if(fd > 0) { break; }
		usleep(100000);
	}

	if (ftruncate(fd, sizeof(wifibroadcast_rx_status_t)) == -1) {
		perror("ftruncate");
		exit(1);
	}

	void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (retval == MAP_FAILED) {
		perror("mmap");
		exit(1);
	}
	
	return (wifibroadcast_rx_status_t*)retval;
}


int main(int argc, char *argv[]) {
	
    int packets1 = 0;
    int packets2 = 0;
	int Button = 18;// ENABLE BCM gpio18 pin12
	
//	wPI：wiringPiSetup (void) ;
//  BCM：wiringPiSetupGpio (void) ;
//  physical：wiringPiSetupPhys (void) ;
//	wiringPiSetupGpio();
//	wiringPiSetup()
	if(wiringPiSetupGpio() == -1){
		printf("setup WiringPi failed");
		return 1;
	}
	pinMode(Button, INPUT);
	pullUpDnControl(Button, PUD_UP);

    wifibroadcast_rx_status_t *t = status_memory_open();

	for(;;)	{
		packets1 = t->received_packet_cnt;
//		printf("Packets1:%d, Packets2:%d\n",packets1,packets2);
		if (packets1 == packets2) {
			printf("0\n");
			break;
//			exit(0);
		} else {
			if (digitalRead(Button) == 0) {
				printf("1\n");
				break;
//				exit(1);
			}
			packets2 = packets1;
			usleep(900000);
		}
	}
    return 0;
}
