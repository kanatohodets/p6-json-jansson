use v6;
use Test;
use lib 'lib';
use JSON::Jansson;


my %hash = (a => 1);
my $encoded-hash = to-json(%hash);
is $encoded-hash, <{"a": 1}>, "basic hash encoding";

my @array = (4, 5, "c", "d");
my $encoded-array = to-json(@array);
is $encoded-array, <[4, 5, "c", "d"]>, "basic array encoding";

%hash<nested-array> = @array;
%hash<nested-hash> = (foo => 6, 9 => 7);
my $encoded-nested-hash = to-json(%hash);
my $nested-array-match = <"nested-array": [4, 5, "c", "d"]>;
is so $encoded-nested-hash ~~ /$nested-array-match/, True, "complex object nesting 1";

my %hash-with-numeric-keys = (0 => "a", 1 => "b");
lives-ok {to-json %hash-with-numeric-keys}, 'convert a hash with numeric keys';

is to-json([]), '[]', "encode empty array";
is to-json({}), '{}', "encode empty hash";
is to-json(().hash), '{}', 'encode ().hash';
is to-json(().list), '[]', 'encode ().list';

my $pushkin = " я помню чудное мгновенье ";
is to-json([$pushkin]), <<[\"$pushkin\"]>>, 'encode array containing cyrillic';

is to-json((undefined => <undefined>)), '{"undefined": "undefined"}', 'encode "undefined"';
#is to-json((foo => Nil)), '{"foo": null}', 'does "Nil" encode into JSON null as an object value?';
#is to-json($nil), 'null', 'does "Nil" encode into JSON null as a plain value?';
dies-ok { to-json(sub { say "I can't be encoded!" }) }, "encode dies on un-encodable value";

done-testing;
