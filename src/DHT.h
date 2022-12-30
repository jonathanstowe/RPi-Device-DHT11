#ifndef _DHT_H_
#define _DHT_H_

#include <wiringPi.h>
#include <stdio.h>
#include <stdint.h>

#define DHTLIB_OK               0
#define DHTLIB_ERROR_CHECKSUM   -1
#define DHTLIB_ERROR_TIMEOUT    -2
#define DHTLIB_INVALID_VALUE    -999

#define DHTLIB_DHT11_WAKEUP     18
#define DHTLIB_DHT_WAKEUP       1

#define DHTLIB_TIMEOUT          100

typedef struct {
	uint8_t bits[5];
} dht11_data;

int32_t read_sensor(dht11_data *data, uint32_t pin, uint32_t wakeup_delay);

#endif
