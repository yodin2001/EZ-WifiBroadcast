// syslogger.c (c) 2017 by Rodizio. Logger for system and tx injection stats Licensed under GPL2
// usage: ./syslogger <shared memory file>
// example: ./syslogger /wifibroadcast_rx_status_sysair
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

wifibroadcast_rx_status_t_sysair *status_memory_open_sysair(char* shm_file) {
	int fd;
	for(;;) {
		fd = shm_open(shm_file, O_RDWR, S_IRUSR | S_IWUSR);
		if(fd > 0) {
			break;
		}
//		fprintf(stderr,"syslogger: Waiting for rssirx to be started ...\n");
		usleep(3000000);
	}
	if (ftruncate(fd, sizeof(wifibroadcast_rx_status_t_sysair)) == -1) {
		perror("ftruncate");
		exit(1);
	}
	void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t_sysair), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (retval == MAP_FAILED) {
		perror("mmap");
		exit(1);
	}
	return (wifibroadcast_rx_status_t_sysair*)retval;
}

status_t_sys_gnd *status_memory_open_sysgnd(char* shm_file) {
	int fd;
	for(;;) {
		fd = shm_open(shm_file, O_RDWR, S_IRUSR | S_IWUSR);
		if(fd > 0) {
			break;
		}
//		fprintf(stderr,"gnd_status: Waiting for shm to be created ...\n");
		usleep(3000000);
	}
	if (ftruncate(fd, sizeof(status_t_sys_gnd)) == -1) {
		perror("ftruncate");
		exit(1);
	}
	void *retval = mmap(NULL, sizeof(status_t_sys_gnd), PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (retval == MAP_FAILED) {
		perror("mmap");
		exit(1);
	}
	return (status_t_sys_gnd*)retval;
}

long long current_timestamp() {
    struct timeval te;
    gettimeofday(&te, NULL); // get current time
    long long milliseconds = te.tv_sec*1000LL + te.tv_usec/1000; // caculate milliseconds
    return milliseconds;
}

int main(int argc, char *argv[]) {
	wifibroadcast_rx_status_t_sysair *t = status_memory_open_sysair(argv[1]);
	status_t_sys_gnd *t_sys_gnd = status_memory_open_sysgnd("/wifibroadcast_rx_status_sys_gnd");
//	wPI：wiringPiSetup (void) ;
//  BCM：wiringPiSetupGpio (void) ;
//  physical：wiringPiSetupPhys (void) ;
//	wiringPiSetupGpio();
//	wiringPiSetup()
	if(wiringPiSetupGpio() == -1){
		printf("setup WiringPi failed");
		return 1;
	}
	int fan = 12;// FAN BCM gpio12 pin32
	pinMode (fan, PWM_OUTPUT) ;
	pwmSetMode(PWM_MODE_MS);
	pwmSetClock(768);
	pwmSetRange(100); //PWM frequency=19200000/768/100=250Hz

	int skipped_fec, skipped_fec_last, skipped_fec_per_second = 0;
	int injected_block, injected_block_last, injected_block_per_second = 0;
	int injection_fail, injection_fail_last, injection_fail_per_second = 0;

	float counter = 0;

	int cpuload_gnd = 0;
	int temp_gnd = 0;
	float gnd_voltage = 0;
	long double a[4], b[4];

	for(;;) {
		// .csv format is:
		// counter, cpuload air, temp air, cpuload gnd, temp gnd, injection_time_block, skipped_fec_cnt/s, injected_block_cnt/s, injection_fail_cnt/s
		printf("%.1f,%d,%d,", counter,t->cpuload, t->temp);

		temp_gnd = t_sys_gnd->temp;
		//fprintf(stderr,"temp gnd:%d\n",temp_gnd/1000);
		cpuload_gnd = t_sys_gnd->cpuload;
		//fprintf(stderr,"cpuload gnd:%d\n",cpuload_gnd);
		gnd_voltage = t_sys_gnd->voltage;
		//fprintf(stderr,"supply voltage:%.2f\n",gnd_voltage);


		if (temp_gnd > 60) {
			pwmWrite (fan, 60) ;
		} else if (temp_gnd < 50) {
			pwmWrite (fan, 0) ;
		}

		printf("%d,%d",cpuload_gnd,temp_gnd);

		printf("%lli,",t->injection_time_block);

        skipped_fec = t->skipped_fec_cnt;
		skipped_fec_per_second = (skipped_fec - skipped_fec_last);
		skipped_fec_last = t->skipped_fec_cnt;
        injected_block = t->injected_block_cnt;
		injected_block_per_second = (injected_block - injected_block_last);
		injected_block_last = t->injected_block_cnt;
        injection_fail = t->injection_fail_cnt;
		injection_fail_per_second = (injection_fail - injection_fail_last);
		injection_fail_last = t->injection_fail_cnt;
        printf("%d,%d,%d\n", skipped_fec_per_second,injected_block_per_second, injection_fail_per_second);

		fflush(stdout);
		usleep(1000000);
		counter = counter + 1;
	}
	return 0;
}
