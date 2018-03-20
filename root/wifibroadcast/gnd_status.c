#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/i2c-dev.h>
#include "lib.h"

#define __REG_BUSVOLTAGE        0x02
#define __BUS_MILLIVOLTS_LSB    4       // 4mV
#define ina219_address          0x40

int init_i2c(uint8_t address)
{
	char *filename = (char*)"/dev/i2c-1";
	int fd = -1;
	if ((fd = open(filename, O_RDWR)) < 0)
	{
		perror("Failed to open the i2c bus");
		return -2;
	}
	if (ioctl(fd, I2C_SLAVE, address) < 0)
	{
		perror("Failed to acquire bus access and/or talk to slave device: ");
		return -3;
	}
	return fd;
}

uint16_t read_i2c_register(int fd, uint8_t register_address)
{
	if(fd <= 0) return 0;

	uint8_t buf[3];
	buf[0] = register_address;
	if (write(fd, buf, 1) != 1) {
		perror("Failed to set register");
	}
	usleep(1000);
	if (read(fd, buf, 2) != 2) {
		perror("Failed to read register value");
	}
	return (buf[0] << 8) | buf[1];
}

float ina219_voltage(int fd)
{
	uint16_t value = read_i2c_register(fd, __REG_BUSVOLTAGE) >> 3;
	return (float)value * __BUS_MILLIVOLTS_LSB / 1000.0;
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

int main(int argc, char *argv[])
{
    int ina219_fd = init_i2c(ina219_address);
    status_t_sys_gnd *t = status_memory_open_sysgnd("/wifibroadcast_rx_status_sys_gnd");
    int temp_gnd = 0;
    int cpuload_gnd = 0;
    long double a[4], b[4] = {0};
    FILE *fp_undervolt;
    FILE *fp_load;
    FILE *fp_gnd_temp;

    while(1)
    {
        //Undervoltage status
        fp_undervolt = fopen("/tmp/undervolt","r");
        if(fp_undervolt == NULL)
        {
            perror("ERROR: Could not open /tmp/undervolt");
            exit(EXIT_FAILURE);
        }
        fscanf(fp_undervolt,"%c",&(t->undervolt));
        fclose(fp_undervolt);

        //CPU load
        fp_load = fopen("/proc/stat","r");
		fscanf(fp_load,"%*s %Lf %Lf %Lf %Lf",&a[0],&a[1],&a[2],&a[3]);
		fclose(fp_load);
		cpuload_gnd = (((b[0]+b[1]+b[2]) - (a[0]+a[1]+a[2])) / ((b[0]+b[1]+b[2]+b[3]) - (a[0]+a[1]+a[2]+a[3]))) * 100;
        t->cpuload = cpuload_gnd;
        printf("cpuload gnd:%d\n",t->cpuload);

        //CPU temperature
        fp_gnd_temp = fopen("/sys/class/thermal/thermal_zone0/temp","r");
		fscanf(fp_gnd_temp,"%d",&temp_gnd);
		fclose(fp_gnd_temp);
        t->temp = temp_gnd/1000;
        //printf("temp gnd:%d\n",t->temp);

        //supply voltage by ina219 sensor
        if(ina219_fd > 0)
		{
            t->voltage = ina219_voltage(ina219_fd);
            //printf("supply voltage: %.2f\n", t->voltage);
        }
        usleep(1e6);
    }
    

    return 0;
}
