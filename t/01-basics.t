use v6;
use Test;
use lib 'lib';
use JSON::Jansson;

sub test-big-object($big-object) {
    isa_ok $big-object.type, 'Associative', "big object is Associative";
    
    is $big-object<guid>, "fa418d28-e32d-4854-81c7-19de7bca5127", "guid lookup is correct";
    
    my @keys = $big-object.keys;
    is +@keys, 15, "big object has 15 keys";
    is @keys.sort.join('/'), 
       "_id/age/balance/dup-tags/favoriteFruit/friends/greeting/guid/index/isActive/latitude/longitude/registered/system/tags",
       "and they are the correct keys";
    
    is $big-object<tags>.enumerate.join('/'), 
       "occaecat/sit/quis/laboris/proident/magna/tempor",
       "tags attribute is correct";
    
    my @a := $big-object<tags>.enumerate;
    my @b := $big-object<dup-tags>.enumerate;
    is @a.join('/'),
       "occaecat/sit/quis/laboris/proident/magna/tempor",
       "tags attribute is correct even reached lazily";
    is @b.join('/'),
       "occaecat/sit/quis/laboris/proident/magna/tempor",
       "dup-tags attribute is correct even reached lazily";

    # say $big-object<system>{"Origin"}.json.WHICH;
    # say $big-object<system>{"X Axis"}.json.WHICH;
    
    my $a = $big-object<system>{"Origin"};
    my $b = $big-object<system>{"X Axis"};
    @a := $a.enumerate;
    @b := $b.enumerate;
    
    is @a.join("/"), "0/0/0", "Origin is lazily correct";
    is @b.join("/"), "1/0/0", "X Axis is lazily correct";
    
    @a := $a.enumerate;
    @b := $b.enumerate;

    is @a.join("/"), "0/0/0", "Origin is still lazily correct";
    is @b.join("/"), "1/0/0", "X Axis is still lazily correct";
}

my $fh = open "t/small.json";
my $data = $fh.slurp-rest;
my $json = Jansson.new($data);

isa_ok $json, JSON::Array, "We got a JSON::Array object";
isa_ok $json.type, 'Positional', ".type returns type object Positional";
is $json.elems, 1, ".elems returns 1";

# my @json-as-array = $json.enumerate;
# is +@json-as-array, 1, "json-as-array has one element";
# {
#     my $big-object = @json-as-array.shift;
#     test-big-object($big-object);
# }

my $big-object = $json[0];
test-big-object($big-object);

done;
