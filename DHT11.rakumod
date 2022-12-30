#!/usr/bin/env raku

class DHT11 {
    use RPi::Wiring::Pi;

    constant DHTLIB_OK               =  0;
    constant DHTLIB_ERROR_CHECKSUM   =  -1;
    constant DHTLIB_ERROR_TIMEOUT    =  -2;
    constant DHTLIB_INVALID_VALUE    =  -999;
;
    constant DHTLIB_DHT11_WAKEUP     =  20;
    constant DHTLIB_DHT_WAKEUP       =  1;
;
    constant DHTLIB_TIMEOUT          =  100;

    has uint8 @!bits = 0,0,0,0,0;

    has Int $.pin is required;

    has Numeric $.temperature;
    has Numeric $.humidity;

    method TWEAK() {
        if wiringPiSetup() == -1 {
            die "couldn't setup wiringpi";
        }
    }

    method read-sensor(int $wakeup-delay ) {
        my int $mask = 0x80;
        my int $idx = 0;
        my int $i ;
        my Int $t;

        @!bits = 0,0,0,0,0;

        pinMode($!pin,OUTPUT);
        digitalWrite($!pin,HIGH);
        delay(500);
        digitalWrite($!pin,LOW);
        delay($wakeup-delay);
        digitalWrite($!pin,HIGH);
        pinMode($!pin,INPUT);

        $t = micros();

        loop {
            if digitalRead($!pin) == LOW {
                last;
            }
            if ( micros() - $t ) > DHTLIB_TIMEOUT {
                return DHTLIB_ERROR_TIMEOUT;
            }
        }

        $t = micros();
        while digitalRead($!pin) == LOW {
            if ( micros() - $t ) > DHTLIB_TIMEOUT {
                return DHTLIB_ERROR_TIMEOUT;
            }
        }
        $t = micros();
        while digitalRead($!pin) == HIGH {
            if ( micros() - $t ) > DHTLIB_TIMEOUT {
                return DHTLIB_ERROR_TIMEOUT;
            }
        }

        for ^40 -> $i {
            $t = micros();
            while digitalRead($!pin) == LOW {
                if ( micros() - $t ) > DHTLIB_TIMEOUT {
                    return DHTLIB_ERROR_TIMEOUT;
                }
            }
            $t = micros();
            while digitalRead($!pin) == HIGH {
                if ( micros() - $t ) > DHTLIB_TIMEOUT {
                    return DHTLIB_ERROR_TIMEOUT;
                }
            }

            if ( micros() - $t ) > 60 {
                @!bits[$idx] +|= $mask;
            }

            $mask +>= 1;

            if $mask == 0 {
                $mask = 0x80;
                $idx++;
            }
        }

        pinMode($!pin,OUTPUT);
        digitalWrite($!pin,HIGH);
        return DHTLIB_OK;
    }

    method read-once( --> Int ) {
        given self.read-sensor(DHTLIB_DHT11_WAKEUP) {
            when DHTLIB_OK {
                $!humidity = @!bits[0];
                $!temperature = @!bits[2] + @!bits[3] * 0.1;
                my $sum = @!bits[^4].sum;
                if @!bits[4] != $sum {
                    DHTLIB_ERROR_CHECKSUM;
                }
                else {
                    $_;
                }
            }
            default {
                $!humidity = DHTLIB_INVALID_VALUE;
                $!temperature = DHTLIB_INVALID_VALUE;
                $_;
            }
        }

    }

    method read( --> Int ) {
        my $rv = DHTLIB_INVALID_VALUE;
        for ^15 {
            given self.read-once {
                when DHTLIB_OK {
                    $rv = $_;
                    last;
                }
                default {
                    $rv = $_;
                    delay(100);
                }
            }
        }
        $rv;
    }
    sub MAIN() is export {
        my $dht = DHT11.new(pin => 0);

        loop {
            for ^15 {
                if ($dht.read == DHTLIB_OK)  {
                    last;
                }
                sleep(0.001);
            }
            say sprintf "Humidity is %.2f %%, \t Temperature is %.2f *C", $dht.humidity, $dht.temperature;
        }
    }
}
# vim: ft=raku
