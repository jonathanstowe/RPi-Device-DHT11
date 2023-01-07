class RPi::Device::DHT11 {

    use NativeCall;

    constant LIB = %?RESOURCES<libraries/dht>.Str;

    constant DHTLIB_OK               =  0;
    constant DHTLIB_ERROR_CHECKSUM   =  -1;
    constant DHTLIB_ERROR_TIMEOUT    =  -2;
    constant DHTLIB_INVALID_VALUE    =  -999;
    constant DHTLIB_DHT11_WAKEUP     =  20;
    constant DHTLIB_DHT_WAKEUP       =  1;
    constant DHTLIB_TIMEOUT          =  120;

    has uint8 @!bits = 0,0,0,0,0;

    has Int $.pin is required;

    has Numeric $.temperature;
    has Numeric $.humidity;


    sub init_dh11( --> int32 ) is native(LIB) { * }

    method TWEAK() {
        init_dh11();
    }

    class Data is repr('CStruct') {
        HAS uint8 @.bits[5] is CArray;

        method TWEAK() {
            for ^5 -> $i {
                @!bits[$i] = 0;
            }
        }
        sub read_sensor(Data $data is rw, uint32 $pin, uint32 $wakeup-delay --> int32 ) is native(LIB) { * }

        method read-sensor(uint32 $pin, uint32 $wakeup-delay --> int32) {
            read_sensor(self, $pin, $wakeup-delay);
        }
    }


    has Data $.data handles <read-sensor> = Data.new;


    method read-once( --> Int ) {
        given self.read-sensor($!pin, DHTLIB_DHT11_WAKEUP) {
            when DHTLIB_OK {
                $!humidity = $!data.bits[0];
                $!temperature = $!data.bits[2] + $!data.bits[3] * 0.1;
                my $sum = $!data.bits[^4].sum;
                if $!data.bits[4] != $sum {
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
                    #delay(100);
                }
            }
        }
        $rv;
    }

    class Reading {
        has Numeric $.temperature;
        has Numeric $.humidity;
    }

    method Supply( --> Supply ) {
        supply {
            whenever Supply.interval(1.5) -> $ {
                for ^15 {
                    if (self.read == DHTLIB_OK)  {
                        last;
                    }
                    sleep(0.01);
                }
                emit Reading.new(temperature => $.temperature, humidity => $.humidity);
            }
        }
    }

}
# vim: ft=raku
