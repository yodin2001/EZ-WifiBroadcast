#!/usr/bin/python

import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(24, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setmode(GPIO.BCM)
GPIO.setup(23, GPIO.IN, pull_up_down=GPIO.PUD_UP)

input_state0 = GPIO.input(24)
input_state1 = GPIO.input(23)

# True = not connected, False = connected to GND

if (input_state0 == True) and (input_state1 == True):
	print ('wifibroadcast-1.txt')
	quit()

if (input_state0 == True) and (input_state1 == False):
	print ('wifibroadcast-2.txt')
	quit()

if (input_state0 == False) and (input_state1 == True):
	print ('wifibroadcast-3.txt')
	quit()

if (input_state0 == False) and (input_state1 == False):
	print ('wifibroadcast-4.txt')
	quit()

