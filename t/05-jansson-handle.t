use v6;
use Test;
use lib 'lib';
use JSON::Jansson;

my $array-json = '[1, 2, "blorg", "bop"]';
my $jansson = jansson-from-json($array-json);
is $jansson.gist, '[1, 2, "blorg", "bop"]', "jansson handle gist into JSON";
$jansson[2] = "pow";
is $jansson.gist, '[1, 2, "pow", "bop"]', "reassign index in array jansson handle";

is $jansson.len, 4, "jansson.len on an array";
$jansson.delete_pos(2);
is $jansson.gist, '[1, 2, "bop"]', "delete_pos removed item";
is $jansson.len, 3, "delete_pos updated array length";
is $jansson[2], "bop", "delete_pos updated index references";

$jansson[4] = "way over the limit";
is $jansson.gist, '[1, 2, "bop", null, "way over the limit"]', 'array auto-extension with null items';

done;
