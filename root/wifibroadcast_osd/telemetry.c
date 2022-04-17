#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>        /* For mode constants */
#include <fcntl.h>           /* For O_* constants */
#include <stdio.h>
#include <stdlib.h>
#include "telemetry.h"
#include "osdconfig.h"

void telemetry_init(telemetry_data_t *td) {
	td->validmsgsrx = 0;
	td->datarx = 0;

	td->voltage = 0;
	td->ampere = 0;
	td->mah = 0;
	td->msl_altitude = 0;
	td->rel_altitude = 0;
	td->longitude = 0;
	td->latitude = 0;
	td->heading = 0;
	td->cog = 0;
	td->speed = 0;
	td->airspeed = 0;
	td->throttle = 0;
	td->roll = 0;
	td->pitch = 0;
	td->sats = 0;
	td->fix = 0;
	td->hdop=0;
	td->armed = 255;
	td->rssi = 0;
	td->home_fix = 0;

	td->mav_climb = 0;
	td->vx=0;
	td->vy=0;
	td->vz=0;

	td->home_lat=0;
	td->home_lon=0;
	td->msg.ts = 0;
	td->msg.message = malloc(51);

	td->rangefinder.current_range = 0;
	td->rangefinder.max_range = 0;
#ifdef FRSKY
	td->x = 0;
	td->y = 0;
	td->z = 0;
	td->ew = 0;
	td->ns = 0;
#endif

#ifdef MAVLINK
    td->mav_flightmode = 255;
 //   td->mav_climb = 0;
	td->version=0;
	td->vendor=0;
	td->product=0;
//	td->vx=0;
//	td->vy=0;
//	td->vz=0;
//	td->hdop = 0;
	td->servo1 = 1500;
	td->mission_current_seq = 0;
	td->SP = 0;
	td->SE = 0;
	td->SH = 0;
	td->total_amps = 0;
	td->wp_dist = 0;
	td->terrain_data.current_height = 0;
	td->terrain_data.loaded = 0;
	td->terrain_data.spacing = 0;
	td->terrain_data.terrain_height = 0;
	td->uav_system_time.time_boot = 0;
	td->uav_system_time.time_unix_usec = 0;
#endif

#ifdef LTM
// ltm S frame
   	 td->ltm_status = 0;
   	 td->ltm_failsafe = 0;
   	 td->ltm_flightmode = 0;
// ltm N frame
   	 td->ltm_gpsmode = 0;
   	 td->ltm_navmode = 0;
   	 td->ltm_navaction = 0;
    	td->ltm_wpnumber = 0;
    	td->ltm_naverror = 0;
// ltm X frame
//   td->ltm_hdop = 0;
    	td->ltm_hw_status = 0;
    	td->ltm_x_counter = 0;
    	td->ltm_disarm_reason = 0;
// ltm O frame
   	 td->ltm_home_altitude = 0;
    	td->ltm_home_longitude = 0;
    	td->ltm_home_latitude = 0;
#endif

#ifndef RELAY
	td->status_sys_gnd = status_memory_open_sys_gnd();
	#ifdef DOWNLINK_RSSI
		td->rx_status = telemetry_wbc_status_memory_open();
	#endif

	#ifdef UPLINK_RSSI
		td->rx_status_uplink = telemetry_wbc_status_memory_open_uplink();
		td->rx_status_rc = telemetry_wbc_status_memory_open_rc();
	#endif

	td->rx_status_osd = telemetry_wbc_status_memory_open_osd();
	td->rx_status_sysair = telemetry_wbc_status_memory_open_sysair();
#else
	td->status_sys_gnd = malloc(sizeof(status_t_sys_gnd));
	td->status_sys_gnd->cpuload = 0;
    td->status_sys_gnd->temp = 0;
	td->status_sys_gnd->undervolt = 0;
	td->status_sys_gnd->voltage = 0;
	td->rx_status->damaged_block_cnt = 0;
	td->rx_status->lost_packet_cnt = 0;
	td->rx_status->skipped_packet_cnt = 0;
	td->rx_status->injection_fail_cnt = 0;
	td->rx_status->received_packet_cnt = 0;
	td->rx_status->kbitrate = 0;
	td->rx_status->kbitrate_measured = 0;
	td->rx_status->kbitrate_set = 0;
	td->rx_status->lost_packet_cnt_telemetry_up = 0;
	td->rx_status->lost_packet_cnt_telemetry_down = 0;
	td->rx_status->lost_packet_cnt_msp_up = 0;
	td->rx_status->lost_packet_cnt_msp_down = 0;
	td->rx_status->lost_packet_cnt_rc = 0;
	td->rx_status->current_signal_joystick_uplink = 0;
	td->rx_status->current_signal_telemetry_uplink = 0;
	td->rx_status->joystick_connected = 0;
	td->rx_status->HomeLat = 0;
	td->rx_status->HomeLon = 0;
	td->rx_status->cpuload_gnd = 0;
	td->rx_status->temp_gnd = 0;
	td->rx_status->cpuload_air = 0;
	td->rx_status->temp_air = 0;
	td->rx_status->wifi_adapter_cnt = 1;
	int i = 0;
	for(i=0; i < 6; i++)
	{
		td->rx_status->adapter[i].received_packet_cnt = 0;
    	td->rx_status->adapter[i].current_signal_dbm = 0;
    	td->rx_status->adapter[i].type = 0; // 0 = Atheros, 1 = Ralink
    	td->rx_status->adapter[i].signal_good = 0;
	}
#endif
}

#ifndef RELAY
status_t_sys_gnd *status_memory_open_sys_gnd(void) {
        int fd = 0;
	int sharedmem = 0;
	while(sharedmem == 0) {
	    fd = shm_open("/wifibroadcast_rx_status_sys_gnd", O_RDONLY, S_IRUSR | S_IWUSR);
    	    if(fd < 0) {
                fprintf(stderr, "OSD: ERROR: Could not open /wifibroadcast_rx_status_sys_gnd - will try again ...\n");
    	    } else {
		sharedmem = 1;
	    }
	    usleep(100000);
	}
        void *retval = mmap(NULL, sizeof(status_t_sys_gnd), PROT_READ, MAP_SHARED, fd, 0);
        if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
        return (status_t_sys_gnd*)retval;
}
#ifdef DOWNLINK_RSSI
wifibroadcast_rx_status_t *telemetry_wbc_status_memory_open(void) {
        int fd = 0;
	int sharedmem = 0;
	while(sharedmem == 0) {
	    fd = shm_open("/wifibroadcast_rx_status_0", O_RDONLY, S_IRUSR | S_IWUSR);
    	    if(fd < 0) {
                fprintf(stderr, "OSD: ERROR: Could not open /wifibroadcast_rx_status_0 - will try again ...\n");
    	    } else {
		sharedmem = 1;
	    }
	    usleep(100000);
	}
        void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t), PROT_READ, MAP_SHARED, fd, 0);
        if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
        return (wifibroadcast_rx_status_t*)retval;
}
#endif

wifibroadcast_rx_status_t_osd *telemetry_wbc_status_memory_open_osd(void) {
        int fd = 0;
	int sharedmem = 0;
	while(sharedmem == 0) {
	    fd = shm_open("/wifibroadcast_rx_status_1", O_RDONLY, S_IRUSR | S_IWUSR);
    	    if(fd < 0) {
                fprintf(stderr, "OSD: ERROR: Could not open /wifibroadcast_rx_status_1 - will try again ...\n");
    	    } else {
		sharedmem = 1;
	    }
	    usleep(100000);
	}
        void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t_osd), PROT_READ, MAP_SHARED, fd, 0);
        if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
        return (wifibroadcast_rx_status_t_osd*)retval;
}


#ifdef UPLINK_RSSI
wifibroadcast_rx_status_t_rc *telemetry_wbc_status_memory_open_rc(void) {
        int fd = 0;
	int sharedmem = 0;
	while(sharedmem == 0) {
	    fd = shm_open("/wifibroadcast_rx_status_rc", O_RDONLY, S_IRUSR | S_IWUSR);
    	    if(fd < 0) {
                fprintf(stderr, "OSD: ERROR: Could not open wifibroadcast_rx_status_rc - will try again ...\n");
    	    } else {
		sharedmem = 1;
	    }
	    usleep(100000);
	}
        void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t_rc), PROT_READ, MAP_SHARED, fd, 0);
        if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
        return (wifibroadcast_rx_status_t_rc*)retval;
}

wifibroadcast_rx_status_t_uplink *telemetry_wbc_status_memory_open_uplink(void) {
        int fd = 0;
	int sharedmem = 0;
	while(sharedmem == 0) {
	    fd = shm_open("/wifibroadcast_rx_status_uplink", O_RDONLY, S_IRUSR | S_IWUSR);
    	    if(fd < 0) {
                fprintf(stderr, "OSD: ERROR: Could not open wifibroadcast_rx_status_uplink - will try again ...\n");
    	    } else {
		sharedmem = 1;
	    }
	    usleep(100000);
	}
        void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t_uplink), PROT_READ, MAP_SHARED, fd, 0);
        if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
        return (wifibroadcast_rx_status_t_uplink*)retval;
}
#endif

wifibroadcast_rx_status_t_sysair *telemetry_wbc_status_memory_open_sysair(void) {
        int fd = 0;
	int sharedmem = 0;
	while(sharedmem == 0) {
	    fd = shm_open("/wifibroadcast_rx_status_sysair", O_RDONLY, S_IRUSR | S_IWUSR);
    	    if(fd < 0) {
                fprintf(stderr, "OSD: ERROR: Could not open wifibroadcast_rx_status_sysair - will try again ...\n");
    	    } else {
		sharedmem = 1;
	    }
	    usleep(100000);
	}
        void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t_sysair), PROT_READ, MAP_SHARED, fd, 0);
        if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
        return (wifibroadcast_rx_status_t_sysair*)retval;
}
#endif
