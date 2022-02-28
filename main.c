/*
Copyright (c) 2015, befinitiv
Copyright (c) 2012, Broadcom Europe Ltd
modified by Samuel Brucksch https://github.com/SamuelBrucksch/wifibroadcast_osd
modified by Rodizio

All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of the copyright holder nor the
names of its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/select.h>
#include <locale.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <poll.h>

#include "render.h"
#include "osdconfig.h"
#include "telemetry.h"
#ifndef RELAY
#include "telemetry_loger.h"
#endif
#ifdef FRSKY
#include "frsky.h"
#elif defined(LTM)
#include "ltm.h"
#elif defined(MAVLINK)
#include "mavlink.h"
#elif defined(SMARTPORT)
#include "smartport.h"
#elif defined(VOT)
#include "vot.h"
#endif

#ifdef RELAY
int open_udp_socket(int port, struct pollfd *pollfd_struct)
{
    struct sockaddr_in saddr;
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0)
    {
        perror("Error opening socket");
        exit(1);
    }


    int optval = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (const void *)&optval , sizeof(int));

    bzero((char *) &saddr, sizeof(saddr));
    saddr.sin_family = AF_INET;
    saddr.sin_addr.s_addr = htonl(INADDR_ANY);
    saddr.sin_port = htons((unsigned short)port);

    if (bind(fd, (struct sockaddr *) &saddr, sizeof(saddr)) < 0)
    {
        perror("Bind error");
        exit(1);
    }

    pollfd_struct[0].fd = fd;
    pollfd_struct[0].events = POLLIN;

    if(fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK) < 0)
    {
        perror("Unable to set socket into nonblocked mode");
        exit(1);
    }

    printf("UDP port %d opened\n", port);
    return fd;
}
int udp_poll(struct pollfd (*pfd)[1], int timeout)
{
    int rc = poll(*pfd, 1, timeout);
    if (rc < 0)
    {
        if (errno == EINTR || errno == EAGAIN) return -1;
        perror("Poll error");
        exit(1);
    }

    if (pfd[0]->revents & (POLLERR | POLLNVAL))
    {
        fprintf(stderr, "socket error!");
        exit(1);
    }
    return rc;
}


uint8_t wbc_buf[255];
struct pollfd fds_wbc[1];
int fd_wbc;

void get_wbc_telemetry(telemetry_data_t *td, int timeout)
{
    if (udp_poll(&fds_wbc, timeout) < 0) return;

    if (fds_wbc[0].revents & POLLIN)
    {
        ssize_t rsize;
        while((rsize = recv(fd_wbc, wbc_buf, sizeof(wbc_buf), 0)) >= 0)
        {
            td->rx_status = (wifibroadcast_rx_status_forward_t *)&wbc_buf;
        }
        if (rsize < 0 && errno != EWOULDBLOCK){
            perror("Error receiving packet");
            exit(1);
        }
    }
}


int get_mavlink_udp_telemetry(int fd, telemetry_data_t *td, int timeout)
{
    struct pollfd poll_fd[1];
    int do_render = 0;
    uint8_t buff[263];

    poll_fd[0].fd = fd;

    if ( udp_poll(&poll_fd, timeout) < 0) return 0;
    if (poll_fd[0].revents & (POLLIN | POLLRDNORM))
    {
        ssize_t rsize;
        while((rsize = recv(fd, buff, sizeof(buff), 0)) >= 0)
        {
	        do_render = mavlink_read(td, buff, rsize);
        }
        if (rsize < 0 && errno != EWOULDBLOCK)
        {
            perror("Error receiving packet");
            exit(1);
        }
    }
    return do_render;
}
#endif

long long current_timestamp()
{
    struct timeval te;
    gettimeofday(&te, NULL); // get current time
    long long milliseconds = te.tv_sec*1000LL + te.tv_usec/1000; // caculate milliseconds
    return milliseconds;
}

fd_set set;

struct timeval timeout;

void GetGroundPiSysStateLocal(telemetry_data_t *td)
{
    FILE *fp;
    long double a[4];
    uint8_t undervolt_gnd;
    static long double b[4];

    fp = fopen("/sys/class/thermal/thermal_zone0/temp","r");
    uint32_t gnd_temp = 0;
    fscanf(fp,"%d",&gnd_temp);
    td->status_sys_gnd.temp = gnd_temp/1000;
	fclose(fp);
    //fprintf(stderr,"temp gnd:%d\n",td.status_sys_gnd.temp);
            

	fp = fopen("/proc/stat","r");
	fscanf(fp,"%*s %Lf %Lf %Lf %Lf",&a[0],&a[1],&a[2],&a[3]);
	fclose(fp);
	td->status_sys_gnd.cpuload = (((b[0]+b[1]+b[2]) - (a[0]+a[1]+a[2])) / ((b[0]+b[1]+b[2]+b[3]) - (a[0]+a[1]+a[2]+a[3]))) * 100;
    //fprintf(stderr,"cpuload gnd:%d\n",td.status_sys_gnd.cpuload);

	fp = fopen("/proc/stat","r");
	fscanf(fp,"%*s %Lf %Lf %Lf %Lf",&b[0],&b[1],&b[2],&b[3]);
	fclose(fp);

    //Undervoltage status
    fp = fopen("/tmp/undervolt","r");
    if(fp == NULL)
    {
        perror("ERROR: Could not open /tmp/undervolt");
        exit(EXIT_FAILURE);
    }
    fscanf(fp,"%d",&undervolt_gnd);
    fclose(fp);
    //fprintf(stderr,"undervolt:%d\n",undervolt_gnd);
    td->status_sys_gnd.undervolt = undervolt_gnd;
}








int main(int argc, char *argv[])
{
    fprintf(stderr,"OSD started\n=====================================\n\n");
    setpriority(PRIO_PROCESS, 0, 10);
    setlocale(LC_ALL, "en_GB.UTF-8");

    uint8_t telemBuffer[263]; // Mavlink maximum packet length
    size_t n;

    long long fpscount_ts = 0;
    long long fpscount_ts_last = 0;
    int fpscount = 0;
    int fpscount_last = 0;
    int fps;

    int do_render = 0;
    int counter = 0;

    int telemetry_fd = 0; //telemetry file descriptor
    telemetry_data_t td;
    

    #ifdef FRSKY
        frsky_state_t fs;
    #endif

    #if defined RELAY
        //open wbc socket
        fd_wbc = open_udp_socket(5003, (struct pollfd *) &fds_wbc);
        memset(&wbc_buf, 0, sizeof(wbc_buf));
        td.rx_status = (wifibroadcast_rx_status_forward_t *)&wbc_buf;

        //open mavlink socket
        struct pollfd fds_mavlink[1];
        char *osd_port = getenv("OSD_PORT");
        memset(fds_mavlink, '\0', sizeof(fds_mavlink));
        telemetry_fd = open_udp_socket(osd_port == NULL ? 14550 : atoi(osd_port), (struct pollfd *) &fds_mavlink);
    #else

        struct stat fdstatus;
        signal(SIGPIPE, SIG_IGN);
        char fifonam[100];
        sprintf(fifonam, "/root/telemetryfifo1");

        telemetry_fd = open(fifonam, O_RDONLY | O_NONBLOCK);
        if(-1==telemetry_fd) {
            perror("ERROR: Could not open /root/telemetryfifo1");
            exit(EXIT_FAILURE);
        }
        if(-1==fstat(telemetry_fd, &fdstatus)) {
            perror("ERROR: fstat /root/telemetryfifo1");
            close(telemetry_fd);
            exit(EXIT_FAILURE);
        }
    #endif

    fprintf(stderr,"OSD: Initializing sharedmem ...\n");
    telemetry_init(&td);
    fprintf(stderr,"OSD: Sharedmem init done\n");

    fprintf(stderr,"OSD: Initializing render engine ...\n");
    render_init();
    fprintf(stderr,"OSD: Render init done\n");

    long long prev_time = current_timestamp();
    long long prev_time2 = current_timestamp();

    long long prev_cpu_time = current_timestamp();
    long long delta = 0;

    int undervolt_gnd = 0;
    //FILE *fp3;

    usleep(500000);


//Main cycle    
    while(1)
    {
        //fprintf(stderr," start while ");
        //prev_time = current_timestamp();

        #if defined RELAY
            //read wifibroadcast telemetry from groundPi
            get_wbc_telemetry(&td, 10);

            //read mavlink
            do_render = get_mavlink_udp_telemetry(telemetry_fd, &td, 25);
        #else
	        FD_ZERO(&set);
	        FD_SET(telemetry_fd, &set);
	        timeout.tv_sec = 0;
	        timeout.tv_usec = 50 * 1000;
	        // look for data 50ms, then timeout
	        n = select(telemetry_fd + 1, &set, NULL, NULL, &timeout);
	        if(n > 0)
            { // if data there, read it and parse it
	            n = read(telemetry_fd, telemBuffer, sizeof(telemBuffer));
                //printf("OSD: %d bytes read\n",n);
	            if(n == 0) { continue; } // EOF
		        if(n<0)
                {
		            perror("OSD: read");
		            exit(-1);
		        }
                #ifdef FRSKY
		            frsky_parse_buffer(&fs, &td, telemBuffer, n);
                #elif defined(LTM)
		            do_render = ltm_read(&td, telemBuffer, n);
                #elif defined(MAVLINK)
		            do_render = mavlink_read(&td, telemBuffer, n);
                #elif defined(SMARTPORT)
		            smartport_read(&td, telemBuffer, n);
                #elif defined(VOT)
		        do_render =  vot_read(&td, telemBuffer, n);
                #endif
	        }
        #endif
        
	    counter++;
	    //fprintf(stderr,"OSD: counter: %d\n",counter);
	    // render only if we have data that needs to be processed as quick as possible (attitude)
	    // or if three iterations (~150ms) passed without rendering
	    if ((do_render == 1) || (counter == 3))
        {
		    //fprintf(stderr," rendering! ");
		    prev_time = current_timestamp();
		    fpscount++;
		    render(&td, td.status_sys_gnd.cpuload, td.status_sys_gnd.temp, td.status_sys_gnd.undervolt, fps);
		    long long took = current_timestamp() - prev_time;
		    //fprintf(stderr,"Render took %lldms\n", took);
		    do_render = 0;
		    counter = 0;
	    }


        //telemetry logging
        #ifndef RELAY
            telemetry_loging(&td, current_timestamp(), 5);
        #endif

        //Read ground systemstatus
        #ifndef RELAY
	    delta = current_timestamp() - prev_cpu_time;
	    if (delta > 1000)
        {
		    prev_cpu_time = current_timestamp();
            //fprintf(stderr,"delta > 1000\n");

		    GetGroundPiSysStateLocal(&td);
	    }
        #endif

        //long long took = current_timestamp() - prev_time;
        //fprintf(stderr,"while took %lldms\n", took);

		long long fpscount_timer = current_timestamp() - fpscount_ts_last;
		if (fpscount_timer > 2000)
        {
		    fpscount_ts_last = current_timestamp();
		    fps = (fpscount - fpscount_last) / 2;
		    fpscount_last = fpscount;
            //system("clear");
		    //fprintf(stderr,"OSD FPS: %d\n", fps);
		}
    }
    return 0;
}
