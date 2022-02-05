/*
Autor: krzysztof.mieloszyk@gmail.com
Telegram: Kristof M
*/

#include <stdint.h>
#include <dirent.h> // for internal log file

#include <termios.h>
#include <unistd.h>
#include <stdio.h>
#include <math.h>
#include <stdbool.h>

#include "telemetry_loger.h"

#define LOG_EXTENDED

#define TO_DEG 180.0f / M_PI

bool init_log = false;
bool home_set = false; 
long long prev_time=0;
long long starting_time = 0;

float prev_lat;
float prev_lon;

float home_lat;
float home_lon;

int distance=0; 
int radial_altitude = 0; 
int course=0;
int frequency = 2480;

FILE *file;
char *path="/wbc_tmp/telemetry_log_file.csv";	 

FILE *file_settings;
char *path_settings="/tmp/settings.sh";	



// function for loging telemetry data and video transmision parameters to file
// <atributes>
// current_time: time in [ms]
// times_per_sec: how offen telemetry is loging (min 1 times per sec, max 5 times per sec)
#ifndef RELAY
void telemetry_loging(telemetry_data_t *td,long long current_time,int times_per_sec) 
{
	int time_step = 1000/times_per_sec;

	if (!init_log)
	{	
		// test for good signal 
		int i;
		bool good_signal = false;

		for(i = 0; i < td->rx_status->wifi_adapter_cnt; ++i)  // find out do any card provide transmision link
			if (td->rx_status->adapter[i].signal_good == 1) good_signal = true;

		if (!good_signal) return; // do not loging if there is no any transmision link
	

		//Read radio frequency from settings.sh , for future link_efficiency calculation
		char buff[1000];		
		file_settings = fopen(path_settings,"r");		 
		
		if (file_settings)
		{
			while (!feof(file_settings))
			{
				fgets(buff,1000,file_settings);				
				if (sscanf(buff,"FREQ=%d",&frequency)==1) break; 				
			} 
			fclose(file_settings);
		}	

		// put header to log file
		init_log = true;
		starting_time = (current_time/time_step)*time_step;
		prev_time = starting_time;
		file = fopen(path,"a+");
		fprintf(file,"time,rssi,distance,course,altitude,link efficiency,sats,roll,pitch,heading");	   

	#ifdef LOG_EXTENDED
		fprintf(file,",bitrate,packets,lost_packets,blocks,bad_blocks,latitude,longitude");	   		
	#endif
	
		fprintf(file,"\n");
		
		fclose(file);
	}
	
	if ((current_time - prev_time) >= (time_step))
	{
		file = fopen(path,"a+");
		
		prev_time = (current_time / time_step) * time_step;;
		double tim = (prev_time - starting_time) / 1000.0;

		if (!home_set)
		{
			if (td->fix > 2 && td->sats > 6)
			{
				home_set = true;
				home_lat = td->latitude;
				home_lon = td->longitude;
			}
		}

	    
		int i;
		int best_rssi = -1000;

		for(i = 0; i < td->rx_status->wifi_adapter_cnt; ++i)  // find out which card has best signal (and if atleast one card has a signal)
			if (td->rx_status->adapter[i].signal_good == 1) 
				if (best_rssi < td->rx_status->adapter[i].current_signal_dbm) best_rssi = td->rx_status->adapter[i].current_signal_dbm;
		
		fprintf(file,"%0.2f,%i,",(double)(tim),best_rssi);	
		
		if (home_set)
		{
			if ((prev_lat!=td->latitude)||(prev_lon!=td->longitude)) 
			{	// if possition is updated, calc new distance and course			
		
				prev_lat = td->latitude;
				prev_lon = td->longitude;						
			
				float lat1 = home_lat;
				float long1 = home_lon;
				float lat2 = td->latitude;
				float long2 = td->longitude;
				
                if (td->rel_altitude > td->msl_altitude)
				{
                    radial_altitude = (int)(td->msl_altitude);
				}
		        else
		        {	
					radial_altitude = (int)(td->rel_altitude);	
				}
				// Calculate Distance:
				// taken from tinygps: https://github.com/mikalhart/TinyGPS/blob/master/TinyGPS.cpp#L296
				// returns distance in meters between two positions, both specified
				// as signed decimal-degrees latitude and longitude. Uses great-circle
				// distance computation for hypothetical sphere of radius 6372795 meters.
				// Because Earth is no exact sphere, rounding errors may be up to 0.5%.
				// Courtesy of Maarten Lamers
								
				float delta = (long1-long2)*0.017453292519;
				float sdlong = sin(delta);
				float cdlong = cos(delta);
				lat1 = (lat1)*0.017453292519;
				lat2 = (lat2)*0.017453292519;
				float slat1 = sin(lat1);
				float clat1 = cos(lat1);
				float slat2 = sin(lat2);
				float clat2 = cos(lat2);
				delta = (clat1 * slat2) - (slat1 * clat2 * cdlong);
				delta = delta*delta;
				delta += (clat2 * sdlong)*(clat2 * sdlong);
				delta = sqrt(delta);
				float denom = (slat1 * slat2) + (clat1 * clat2 * cdlong);
				delta = atan2(delta, denom);
				distance = delta * 6372795;
				

				
				// Calculate Course to launch point:
				// taken from tinygps: https://github.com/mikalhart/TinyGPS/blob/master/TinyGPS.cpp#L321
				// returns course in degrees (North=0, West=270) from position 1 to position 2,
				// both specified as signed decimal-degrees latitude and longitude.
				// Because Earth is no exact sphere, calculated course may be off by a tiny fraction.
				// Courtesy of Maarten Lamers

				float dlon = (long2-long1)*0.017453292519;
				//lat1 = (lat1)*0.017453292519; // calculated above
				//lat2 = (lat2)*0.017453292519;
				float a1 = sin(dlon) * cos(lat2);
				float a2 = sin(lat1) * cos(lat2) * cos(dlon);
				a2 = cos(lat1) * sin(lat2) - a2;
				a2 = atan2(a1, a2);
				if (a2 < 0.0) a2 += M_PI*2;
				course = TO_DEG*(a2);			
			}
			fprintf(file,"%i,%i,%i,", distance, course, radial_altitude);
			
			// calc link_efficiency
			int radial_distance = sqrt(distance * distance + radial_altitude * radial_altitude);
			if (radial_distance < 1.0) radial_distance=1.0;
			int link_efficiency = best_rssi - 27.55 + 20 * log10(frequency) + 20 * log10(radial_distance);
			fprintf(file,"%i,",link_efficiency);			
		}
		else
		{
			fprintf(file,"%i,%i,%i,%i,", 100, 0, 0, 0);
		}
		
		fprintf(file,"%i,",td->sats);

		fprintf(file,"%0.1f,%0.1f,%0.1f,",td->roll,td->pitch,td->heading);
		

		//  Telemetry log, extendet part
	#ifdef LOG_EXTENDED	
		fprintf(file,"%i,",td->rx_status->kbitrate);
		
		//fprintf(file,"%i,",td->rx_status_sysair->injection_time_block)
		static int prev_received_packet_cnt=0;
		static int prev_lost_packet_cnt=0;
		static int prev_received_block_cnt=0;
		static int prev_damaged_block_cnt=0;
		
		fprintf(file,"%i,",td->rx_status->received_packet_cnt - prev_received_packet_cnt);
		fprintf(file,"%i,",td->rx_status->lost_packet_cnt - prev_lost_packet_cnt);
		fprintf(file,"%i,",td->rx_status->received_block_cnt - prev_received_block_cnt);
		fprintf(file,"%i,",td->rx_status->damaged_block_cnt - prev_damaged_block_cnt);
		
		prev_received_packet_cnt= td->rx_status->received_packet_cnt;
		prev_lost_packet_cnt 	= td->rx_status->lost_packet_cnt;
		prev_received_block_cnt = td->rx_status->received_block_cnt;
		prev_damaged_block_cnt = td->rx_status->damaged_block_cnt;
		
		fprintf(file,"%0.5f,%0.5f",td->latitude,td->longitude);
		
			// struct of flight telemetry, what can be extract if is needed 
			/* 
			   typedef struct {
			uint32_t validmsgsrx;
			uint32_t datarx;

			float voltage;
			float ampere;
			int32_t mah;
			float baro_altitude;
			float altitude;
			double longitude;
			double latitude;
			float heading;
			float cog; //course over ground
			float speed;
			float airspeed;
			float roll, pitch;
			uint8_t sats;
			uint8_t fix;
			uint8_t armed;
			uint8_t rssi;

			uint8_t home_fix;

			#if defined(MAVLINK)
				uint32_t mav_flightmode;
				float mav_climb;
			#endif
				*/ 
	#endif
		
		fprintf(file,"\n");
		fclose(file);
	}	
}
#endif