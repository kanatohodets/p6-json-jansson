use v6;
use Test;
use JSON::Jansson;

sub test-big-object($big-object) {
    isa_ok $big-object.type, "Hash", "big object is Hash";
    is $big-object<guid>, "fa418d28-e32d-4854-81c7-19de7bca5127", "guid lookup is correct";
    my @keys = $big-object.keys;
    is +@keys, 13, "big object has 13 keys";
}

my $fh = open "t/small.json";
my $data = $fh.slurp;
my $json = JSON.new($data);

isa_ok $json, JSON::Array, "We got a JSON::Array object";
isa_ok $json.type, Array, ".type returns type object Array";
is $json.len, 1, ".len returns 1";

my @json-as-array = $json.enumerate;
is +@json-as-array, 1, "json-as-array has one element";
{
    my $big-object = @json-as-array.shift;
    test-big-object($big-object);
}

my $big-object = $json[0];
test-big-object($big-object);

done;