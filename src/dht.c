/*
 * This is based on the https://github.com/Freenove/Freenove_Ultimate_Starter_Kit_for_Raspberry_Pi/blob/master/Code/C_Code/21.1.1_DHT11/DHT.cpp
 * which is licensed as CC BY-NC-SA 3.0 ( https://github.com/Freenove/Freenove_Ultimate_Starter_Kit_for_Raspberry_Pi/blob/master/LICENSE.txt )
 * It has been modified to work as a plain C library rather than a C++ class
 */
/**********************************************************************
* Filename    : DHT.hpp
* Description : DHT Temperature & Humidity Sensor library for Raspberry.
                Used for Raspberry Pi.
*				Program transplantation by Freenove.
* Author      : freenove
* modification: 2020/10/16
* Reference   : https://github.com/RobTillaart/Arduino/tree/master/libraries/DHTlib
**********************************************************************/
#include <wiringPi.h>
#include "DHT.h"

int32_t init_dh11() {
    return wiringPiSetup();
}

int32_t read_sensor(dht11_data *data, uint32_t pin,uint32_t wakeup_delay){
	int mask = 0x80;
	int idx = 0;
	int i ;
	uint32_t t;
	for (i=0;i<5;i++){
		data->bits[i] = 0;
	}

	pinMode(pin,OUTPUT);
	digitalWrite(pin,HIGH);
	delay(500);

	digitalWrite(pin,LOW);
	delay(wakeup_delay);
	digitalWrite(pin,HIGH);

	pinMode(pin,INPUT);

	uint32_t loopCnt = DHTLIB_TIMEOUT;
	t = micros();

	while(1){
		if(digitalRead(pin)==LOW){
			break;
		}
		if((micros() - t) > loopCnt){
			return DHTLIB_ERROR_TIMEOUT;
		}
	}

	loopCnt = DHTLIB_TIMEOUT;
	t = micros();

	while(digitalRead(pin)==LOW){
		if((micros() - t) > loopCnt){
			return DHTLIB_ERROR_TIMEOUT;
		}
	}

	loopCnt = DHTLIB_TIMEOUT;
	t = micros();

	while(digitalRead(pin)==HIGH){
		if((micros() - t) > loopCnt){
			return DHTLIB_ERROR_TIMEOUT;
		}
	}
	for (i = 0; i<40;i++){
		loopCnt = DHTLIB_TIMEOUT;
		t = micros();
		while(digitalRead(pin)==LOW){
			if((micros() - t) > loopCnt)
				return DHTLIB_ERROR_TIMEOUT;
		}
		t = micros();
		loopCnt = DHTLIB_TIMEOUT;
		while(digitalRead(pin)==HIGH){
			if((micros() - t) > loopCnt){
				return DHTLIB_ERROR_TIMEOUT;
			}
		}
		if((micros() - t ) > 60){
			data->bits[idx] |= mask;
		}
		mask >>= 1;
		if(mask == 0){
			mask = 0x80;
			idx++;
		}
	}
	pinMode(pin,OUTPUT);
	digitalWrite(pin,HIGH);

	return DHTLIB_OK;
}
