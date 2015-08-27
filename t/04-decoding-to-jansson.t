use v6;
use Test;
use lib 'lib';
use JSON::Jansson;

my $object = '{"foo": "bar"}';
my %hash-like-bind := jansson-from-json($object);
is %hash-like-bind<foo>, "bar", "decode simple JSON object into jansson hash-like, fetch key, binding";
is %hash-like-bind<no_such_key>, Any, "missing key is Any, binding";
is %hash-like-bind.keys, ('foo'), "object.keys, binding";
is %hash-like-bind.values, ('bar'), "object.values, binding";
is %hash-like-bind.kv, ('foo', 'bar'), "object.kv, binding";

my $hash-like = jansson-from-json($object);
is $hash-like<foo>, "bar", "decode simple JSON object into jansson hash-like, fetch key, assignment";
is $hash-like<no_such_key>, Any, "missing key is Any, assignment";
is $hash-like.keys, ('foo'), "object.keys, assignment";
is $hash-like.values, ('bar'), "object.values, assignment";
is $hash-like.kv, ('foo', 'bar'), "object.kv, assignment";

my $array = '[1, 2, "blorg", "bop"]';
my @array-like-bind := jansson-from-json($array);
is @array-like-bind[2], "blorg", "decode simple JSON array into jansson array-like, fetch index, binding";
is @array-like-bind[5], Any, "out of bounds Array index is Any, binding";
is @array-like-bind[*-1], "bop", "*-1 end of array access works, binding";

my $array-like = jansson-from-json($array);
is $array-like[2], "blorg", "decode simple JSON array into jansson array-like, fetch index, assignment";
is $array-like[5], Any, "out of bounds Array index is Any, assignment";
is $array-like[*-1], "bop", "*-1 end of array access works, assignment";

my $complex-object = '{"foo": { "bar": { "baz": 42 }}}';
my $complex-hash-like = jansson-from-json($complex-object);
is $complex-hash-like<foo><bar><baz>, 42, "decode complex JSON object into nested jansson hash-likes";
my $complex-array = '[{"theKey": 9}, [3, 4, 5], "abcdef"]';
my $complex-array-like = jansson-from-json($complex-array);
is $complex-array-like[0]<theKey>, 9, "decode complex JSON array into jansson array-like";

throws-like { my $invalid = jansson-from-json("[1, 2, 3,"); }, X::JSON::ParseError, "caught an X::JSON::ParseError on invalid data";

done;
