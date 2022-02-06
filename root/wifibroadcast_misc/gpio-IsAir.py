#!/usr/bin/python

import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.IN, pull_up_down=GPIO.PUD_UP)

input_state0 = GPIO.input(18)

# True = not connected, False = connected to GND
if (input_state0 == False):
    f = open("/tmp/Air", "w")
    f.write("1")
    f.close()
    quit()
if (input_state0 == True):
    f = open("/tmp/Air", "w")
    f.write("0")
    f.close()
    quit()