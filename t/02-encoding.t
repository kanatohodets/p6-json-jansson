use v6;
use Test;
use lib 'lib';
use JSON::Jansson;


my %hash = (a => 1, b => 2);
my $encoded-hash = to-json(%hash);
is $encoded-hash, <{"a": 1, "b": 2}>, "basic hash encoding";

my @array = (4, 5, "c", "d");
my $encoded-array = to-json(@array);
is $encoded-array, <[4, 5, "c", "d"]>, "basic array encoding";

%hash<nested-array> = @array;
%hash<nested-hash> = (foo => 6, 9 => 7);
my $encoded-nested-hash = to-json(%hash);
my $nested-array-match = <"nested-array": [4, 5, "c", "d"]>;
is so $encoded-nested-hash ~~ /$nested-array-match/, True, "complex object nesting 1";

my %hash-with-numeric-keys = (0 => "a", 1 => "b");
lives_ok {to-json %hash-with-numeric-keys}, 'convert a hash with numeric keys';

is to-json([]), '[]', "encode empty array";
is to-json({}), '{}', "encode empty hash";
is to-json(().hash), '{}', 'encode ().hash';
is to-json(().list), '[]', 'encode ().list';

done;
