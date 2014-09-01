use v6;
use Test;
use lib 'lib';
use JSON::Jansson;

my $object = '{"foo": "bar"}';
is from-json($object), { foo => <bar> }, "decode simple JSON object into perl 6 hash";
my $array = '[1, 2, "blorg", "bop"]';
is from-json($array), [1, 2, "blorg", "bop"], "decode simple JSON array into perl 6 array";

my $complex-object = '{"foo": { "bar": { "baz": 42 }}}';
is from-json($complex-object), { foo => { bar => { baz => 42 }}}, "decode complex JSON object into nested perl 6 hashes";
my $complex-array = '[{"theKey": 9}, [3, 4, 5], "abcdef"]';
is from-json($complex-array), [{theKey => 9}, [3, 4, 5], "abcdef"], "decode complex JSON array into perl 6 array";

done;
