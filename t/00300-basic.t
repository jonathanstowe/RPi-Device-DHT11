#!/usr/bin/env raku

use Test;
use Test::Mock;

use RPi::Device::DHT11;

subtest {
    my $data = mocked(RPi::Device::DHT11::Data, returning => {
        read-sensor => 0,
        bits        =>  (76,0, 20, 4, 100 ),
    },);

    my $dht = RPi::Device::DHT11.new(pin => 0, :$data);
    ok my $reading = $dht.read, "read";
    isa-ok $reading, RPi::Device::DHT11::Reading;
    is $reading.temperature, 20.4, "got the right temperature";
    is $reading.humidity, 76, "got the right humidity";


}, "good";

subtest {
    my $data = mocked(RPi::Device::DHT11::Data, returning => {
        read-sensor => 0,
        bits        =>  (76,0, 20, 4, 666 ),
    },);

    my $dht = RPi::Device::DHT11.new(pin => 0, :$data);
    ok !my $reading = $dht.read, "read";
    isa-ok $reading, RPi::Device::DHT11::Reading;
    ok !$reading.defined, "it's a type object";


}, "bad checksum";

subtest {
    my $data = mocked(RPi::Device::DHT11::Data, returning => {
        read-sensor => -2,
        bits        =>  (76,0, 20, 4, 100 ),
    },);

    my $dht = RPi::Device::DHT11.new(pin => 0, :$data);
    ok !my $reading = $dht.read, "read";
    isa-ok $reading, RPi::Device::DHT11::Reading;
    ok !$reading.defined, "it's a type object";


}, "error time out";

done-testing;
# vim: ft=raku
