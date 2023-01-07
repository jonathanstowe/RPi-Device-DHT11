=begin pod

=head1 NAME

RPi::Device::DHT11 - Interface to the DHT11 digital temperature/humidity sensor

=head1 SYNOPSIS

=begin code

use RPi::Device::DHT11;

sub MAIN() {
    my $dht = RPi::Device::DHT11.new(pin => 0, supply-interval => 1.5);

    react {
        whenever $dht -> $reading {
            say sprintf "{ DateTime.now.Str }: Humidity is %.2f %%, \t Temperature is %.2f *C", $reading.humidity, $reading.temperature;
        }
    }
}
=end code

=head1 DESCRIPTION

The DHT11 is a common and inexpensive temperate and humidity sensor with a single pin digital interface. It has a reasonable degree of accuracy ( 1-2% on relative humidity and 0.2°C or so.)

To hook the DHT11 up you only need a pull-up resistor (the datasheets indicate 5KΩ but 10K seems to work fine.) It will not work reliably (or at all,) without the pull-up.

A typical setup would be:

[![Minimal Circuit](examples/hardware/dht11.png)](examples/hardware/dht11.png)

Please note that because this uses the wiringPi library under the hood the [wiringPi pin numbers](http://wiringpi.com/pins/) are used, so in the above the data line is connected to the sixth pin down from the top on the left (assuming the end with the USB is "down",) which is wiringPi pin 0 (or GPIO 17 in the Broadcom numbering.) You can find the actual numbering for your Raspberry Pi with:

    gpio readall

which gives you a convenient table.

The easiest way to use this module is to use the object as a `Supply` as in the example above (it supplies a `Supply` coercion,) this will emit a `Reading` object at a minimum of `supply-interval` seconds frequency (the default is 1.5 seconds which is about the minimum usable value.)  The `Reading` object has `temperature` (in degrees Celsius,) and `humidity` (in percentage relative humidity,) attribute.

The `read` method returns a `Reading` object if a valid reading is obtained in `read-retries` attempts, or a type object otherwise, this doesn't place a constraint on how frequently it is called but you are likely to get fewer valid readings if call more frequently than 1.5 seconds.

You could potentially use multiple instances of this on different pins (having more than one on the same pin is guaranteed not to work,) but you should bear in mind that the code has to spin in a tight loop while it is getting a reading so you might experience high processor load and/or unreliable readings if you have too many.

=end pod

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


    #| The wiringPi Pin number
    has Int     $.pin is required;
    #| The minimum interval at which Reading objects will be emitted by Supply, default is 1.5
    has Numeric $.supply-interval   = 1.5;
    #| The number of times a read will be tried to get a valid reading, default is 15
    has Int     $.read-retries      = 15;

    #| The temperature in Celsius after the most recent reading
    has Numeric $.temperature;
    #| The humidity as a percentage after the most recent reading
    has Numeric $.humidity;



    method TWEAK() {
        $!data.init();
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

        sub init_dh11( --> int32 ) is native(LIB) { * }

        method init() {
            init_dh11();
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

    #| Class representing a single reading
    class Reading {
        #| The temperature in celcius for this reading
        has Numeric $.temperature;
        #| The humidity expressed as percentage for this reading
        has Numeric $.humidity;
    }

    #| Attempt to get a single reading, attempting at most read-retries.
    #| Returns a Reading object if successfull, a type object otherwise
    method read( --> Reading ) {
        my Reading $rv;
        for ^$!read-retries {
            given self.read-once {
                when DHTLIB_OK {
                    $rv = Reading.new(temperature => $.temperature, humidity => $.humidity);
                    last;
                }
            }
        }
        $rv;
    }

    #| Supply coercion, emits Reading objects at a minimum of supply-interval frequency
    method Supply( --> Supply ) {
        supply {
            whenever Supply.interval($!supply-interval) -> $ {
                    if self.read -> $reading {
                        emit $reading;
                    }
            }
        }
    }

}
# vim: ft=raku
