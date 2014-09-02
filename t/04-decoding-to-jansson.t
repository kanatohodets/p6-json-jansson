use v6;
use Test;
use lib 'lib';
use JSON::Jansson;

my $object = '{"foo": "bar"}';
my $hash-like = jansson-from-json($object);
is $hash-like<foo>, "bar", "decode simple JSON object into jansson hash-like, fetch key";

my $array = '[1, 2, "blorg", "bop"]';
my $array-like = jansson-from-json($array);
is $array-like[2], "blorg", "decode simple JSON array into jansson array-like, fetch index";

my $complex-object = '{"foo": { "bar": { "baz": 42 }}}';
my $complex-hash-like = jansson-from-json($complex-object);
is $complex-hash-like<foo><bar><baz>, 42, "decode complex JSON object into nested jansson hash-likes";
my $complex-array = '[{"theKey": 9}, [3, 4, 5], "abcdef"]';
my $complex-array-like = jansson-from-json($complex-array);
is $complex-array-like[0]<theKey>, 9, "decode complex JSON array into jansson array-like";

throws_like { my $invalid = jansson-from-json("[1, 2, 3,"); }, X::JSON::ParseError, "caught an X::JSON::ParseError on invalid data";

done;
