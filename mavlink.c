#include "mavlink.h"
#include <stdio.h>
#include <unistd.h>

#ifdef MAVLINK
mavlink_status_t status;
mavlink_message_t msg;

//no stdoutput by defoult
#ifndef DEBUG
	#define fprintf(...) (0)
#endif


int mavlink_read(telemetry_data_t *td, uint8_t *buf, int buflen)
{
	

	td->datarx++;
	int i = 0;
	int render_data = 0;
	//fprintf(stdout, "buflen: %d  ",buflen);
	//fprintf(stdout, "mavlink_read datarx: %d\n",td->datarx);
	for(i=0; i<buflen; i++) {
		uint8_t c = buf[i];
		if (mavlink_parse_char(0, c, &msg, &status))
		{
            td->validmsgsrx++;
			render_data = 1; //valid packet recieved, need to render
			fprintf(stdout, "Msg seq:%d sysid:%d, compid:%d  ", msg.seq, msg.sysid, msg.compid);

            switch (msg.msgid)
			{
				case MAVLINK_MSG_ID_GLOBAL_POSITION_INT:
					fprintf(stdout, "GLOBAL_POSITION_INT: ");

					#if COMPASS_INAV == true
  						td->heading = mavlink_msg_global_position_int_get_hdg(&msg);
					#else
						td->heading = mavlink_msg_global_position_int_get_hdg(&msg)/100.0f;
    				#endif


                    #if REL_ALT_SOURCE == 1
                    	td->rel_altitude = mavlink_msg_global_position_int_get_relative_alt(&msg)/1000.0f;
						fprintf(stdout, "REL altitude global rel:%.2f  ", td->rel_altitude);
					#endif
					
					
					td->msl_altitude = mavlink_msg_global_position_int_get_alt(&msg)/1000.0f;
					fprintf(stdout, "msl alt global:%.2f  ", td->msl_altitude);


					td->vx = mavlink_msg_global_position_int_get_vx(&msg)/100.0f;
    				td->vy = mavlink_msg_global_position_int_get_vy(&msg)/100.0f;
    				td->vz = mavlink_msg_global_position_int_get_vz(&msg)/100.0f;
					
					fprintf(stdout, "vx:%.2f  ", td->vx);
					fprintf(stdout, "vy:%.2f  ", td->vy);
					fprintf(stdout, "vz:%.2f  ", td->vz);
					

                    td->latitude = mavlink_msg_global_position_int_get_lat(&msg)/10000000.0f;
                    td->longitude = mavlink_msg_global_position_int_get_lon(&msg)/10000000.0f;
					
					fprintf(stdout, "heading:%.2f  ", td->heading);
					fprintf(stdout, "latitude:%.6f  ", td->latitude);
					fprintf(stdout, "longitude:%.6f  ", td->longitude);

					break;


                case MAVLINK_MSG_ID_GPS_RAW_INT:
					//fprintf(stdout, "GPS_RAW_INT: ");
					td->fix = mavlink_msg_gps_raw_int_get_fix_type(&msg);
					td->sats = mavlink_msg_gps_raw_int_get_satellites_visible(&msg);
                	td->hdop = mavlink_msg_gps_raw_int_get_eph(&msg);
					td->cog = mavlink_msg_gps_raw_int_get_cog(&msg)/100.0f;
					
  					#if REL_ALT_SOURCE == 2
  	                    td->rel_altitude = mavlink_msg_gps_raw_int_get_alt(&msg)/1000.0f;
						fprintf(stdout, "REL altitude gps alt:%.2f  ", td->rel_altitude);
					#endif

					//td->latitude = mavlink_msg_gps_raw_int_get_lat(&msg)/10000000.0f;
					//td->longitude = mavlink_msg_gps_raw_int_get_lon(&msg)/10000000.0f;

					//fprintf(stdout, "GPS RAW INT heading:%.2f  ", td->heading);
					//fprintf(stdout, "altitude:%.2f  ", td->rel_altitude);
					//fprintf(stdout, "latitude:%.2f  ", td->latitude);
					//fprintf(stdout, "longitude:%.2f  ", td->longitude);
					//fprintf(stdout, "fix:%d  ", td->fix);
					//fprintf(stdout, "sats:%d  ", td->sats);
					//fprintf(stdout, "hdop:%d  ", td->hdop);
					//fprintf(stdout, "cog:%d  ", td->cog);

					break;


				case MAVLINK_MSG_ID_ATTITUDE:
					fprintf(stdout, "ATTITUDE: ");
					td->roll = mavlink_msg_attitude_get_roll(&msg)*57.2958;
					td->pitch = mavlink_msg_attitude_get_pitch(&msg)*57.2958;
					fprintf(stdout, "roll:%.2f  ", td->roll);
					fprintf(stdout, "pitch:%.2f  ", td->pitch);
					break;


				case MAVLINK_MSG_ID_SYS_STATUS:
					
					td->voltage = mavlink_msg_sys_status_get_voltage_battery(&msg)/1000.0f;
					td->ampere = mavlink_msg_sys_status_get_current_battery(&msg)/100.0f;
					td->SP = mavlink_msg_sys_status_get_onboard_control_sensors_present(&msg);
					td->SE = mavlink_msg_sys_status_get_onboard_control_sensors_enabled(&msg);
					td->SH = mavlink_msg_sys_status_get_onboard_control_sensors_health(&msg);

					fprintf(stdout, "SYS_STATUS: ");
					fprintf(stdout, "voltage:%.2f  ", td->voltage);
					fprintf(stdout, "ampere:%.2f  ", td->ampere);
					fprintf(stdout, "Status1:%d ",td->SP);
					fprintf(stdout, "Status2:%d ",td->SE);
					fprintf(stdout, "Status3:%d ",td->SH);

					break;


                case MAVLINK_MSG_ID_VFR_HUD:
					fprintf(stdout, "VFR_HUD: ");
                    td->speed = mavlink_msg_vfr_hud_get_groundspeed(&msg)*3.6f;
                    td->airspeed = mavlink_msg_vfr_hud_get_airspeed(&msg)*3.6f;

                    #if REL_ALT_SOURCE == 3
						td->rel_altitude = mavlink_msg_vfr_hud_get_alt(&msg);
                        fprintf(stdout, "REL altitude vfr hud:%.2f  ", td->rel_altitude);
                    #endif

					td->mav_climb = mavlink_msg_vfr_hud_get_climb(&msg);
					td->throttle = mavlink_msg_vfr_hud_get_throttle(&msg);
					fprintf(stdout, "speed:%.2f  ", td->speed);
					fprintf(stdout, "airspeed:%.2f  ", td->airspeed);
					//fprintf(stdout, "heading:%.2f  ", td->heading);
					fprintf(stdout, "climb:%f  ", td->mav_climb);
					fprintf(stdout, "throttle:%.2f  ", td->throttle);

                    
					break;


                case MAVLINK_MSG_ID_GPS_STATUS:
					fprintf(stdout, "GPS_STATUS ");

                	break;


                case MAVLINK_MSG_ID_HEARTBEAT:
					fprintf(stdout, "HEARTBEAT ");
					td->mav_flightmode = mavlink_msg_heartbeat_get_custom_mode(&msg);
					//if (((mavlink_msg_heartbeat_get_base_mode(&msg) & 0b10000000) >> 7) == 0) {
					//    td->armed = 0;
					//} else {
					 //   td->armed = 1;
					//}

					td->armed=mavlink_msg_heartbeat_get_base_mode(&msg);

					if (td->armed==0){ 
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 0;} //preflight

					else if (td->armed==64){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 0;} //manual disarm

					else if (td->armed==81){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 0;} //UKNOWN disarm mode

					else if (td->armed==88){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 0;} //guided disarm

					else if (td->armed==92){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 0;} //auto disarm

					else if (td->armed==66){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 0;} //test disarm

					else if (td->armed==208){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 1;} //stab arm

					else if (td->armed==209){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 1;} //UKNOWN arm

					else if (td->armed==192){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 1;} //manual arm

					else if (td->armed==216){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 1;} //guided arm

					else if (td->armed==220){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 1;} //auto arm

					else if (td->armed==194){
						fprintf(stdout, "base mode:%d  ", td->armed);
						td->armed = 1;} //test arm

					else if (td->armed>100){
						fprintf(stdout, "base mode:%d  Greater than 100", td->armed);
						td->armed = 1;} //>100 arm

					else if (td->armed<100){
						fprintf(stdout, "base mode:%d  less than 100", td->armed);
						td->armed = 0;} //>100 arm

					else {fprintf(stdout, "UNKNOWN base mode:%d  ", td->armed);}
	
					fprintf(stdout, "mode:%d  ", td->mav_flightmode);
					fprintf(stdout, "armed:%d  ", td->armed);
                    break;


                case MAVLINK_MSG_ID_RC_CHANNELS_RAW:
					fprintf(stdout, "RC_CHANNELS_RAW ");
					td->rssi = mavlink_msg_rc_channels_raw_get_rssi(&msg)*100/255;
					fprintf(stdout, "rssi:%d  ", td->rssi);
                    break;

                case MAVLINK_MSG_ID_COMMAND_ACK:
					fprintf(stdout, "COMMAND_ACK:%d ",mavlink_msg_command_ack_get_command(&msg));
                    break;


                case MAVLINK_MSG_ID_COMMAND_INT:
					fprintf(stdout, "COMMAND_INT:%d ",mavlink_msg_command_int_get_command(&msg));
                	break;


				case MAVLINK_MSG_ID_AUTOPILOT_VERSION:
					td->version = mavlink_msg_autopilot_version_get_os_sw_version(&msg);
					td->vendor = mavlink_msg_autopilot_version_get_vendor_id(&msg);
					td->product = mavlink_msg_autopilot_version_get_product_id(&msg);

					fprintf(stdout, "version:%d  ", td->version);
					fprintf(stdout, "vendor:%d  ", td->vendor);
					fprintf(stdout, "product:%d  ", td->product);
					break;


                case MAVLINK_MSG_ID_EXTENDED_SYS_STATE:
					fprintf(stdout, "EXTENDED_SYS_STATE: vtol_state:%d, landed_state:%d",mavlink_msg_extended_sys_state_get_vtol_state(&msg),mavlink_msg_extended_sys_state_get_landed_state(&msg));
                    break;
                
				
				case MAVLINK_MSG_ID_SERVO_OUTPUT_RAW:
					td->servo1 = mavlink_msg_servo_output_raw_get_servo1_raw(&msg);
					fprintf(stdout, "SERVO1:%d ",mavlink_msg_servo_output_raw_get_servo1_raw(&msg));
                    break;
                
				
				case MAVLINK_MSG_ID_MISSION_CURRENT:				
					td->mission_current_seq = mavlink_msg_mission_current_get_seq(&msg);
					fprintf(stdout, "MISSION_CURRENT ");
					fprintf(stdout, "MC:%d ", td->mission_current_seq);
                    break;
				
				
				case MAVLINK_MSG_ID_BATTERY_STATUS:
					td->total_amps = mavlink_msg_battery_status_get_current_consumed(&msg);
					fprintf(stdout, "CURRENT_CONSUMED: %d", td->total_amps);
                    break;

				case MAVLINK_MSG_ID_HOME_POSITION:
					td->home_lat = mavlink_msg_home_position_get_latitude(&msg)/10000000.0f;
					td->home_lon = mavlink_msg_home_position_get_longitude(&msg)/10000000.0f;	
					break;


				case MAVLINK_MSG_ID_STATUSTEXT:
					td->msg.ts = current_ts();
					mavlink_msg_statustext_get_text(&msg, td->msg.message);
					td->msg.severity = mavlink_msg_statustext_get_severity(&msg);
					break;


				case MAVLINK_MSG_ID_DISTANCE_SENSOR:
					td->rangefinder.current_range = mavlink_msg_distance_sensor_get_current_distance(&msg)/100.0f;
					td->rangefinder.max_range = mavlink_msg_distance_sensor_get_max_distance(&msg)/100.0f;
					break;

				
				case MAVLINK_MSG_ID_NAV_CONTROLLER_OUTPUT:
					td->wp_dist = mavlink_msg_nav_controller_output_get_wp_dist(&msg);
					break;

                default:
					render_data = 0; //unknown packet, no need to render
                    fprintf(stdout, "OTHER MESSAGE ID:%d ",msg.msgid);
                    break;
			}
			fprintf(stdout, "\n");
			fflush(stdout);
		}
	}
	return render_data;
}
#endif
