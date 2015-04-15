use v6;
use Test;
use lib 'lib';
use JSON::Jansson;

my $array-json = '[1, 2, "blorg", "bop"]';
my $jansson = jansson-from-json($array-json);
is $jansson.gist, '[1, 2, "blorg", "bop"]', "jansson handle gist into JSON";
$jansson[2] = "pow";
is $jansson.gist, '[1, 2, "pow", "bop"]', "reassign index in array jansson handle";

is $jansson[0 ... 2], (1, 2, "pow"), "array slice on a jansson array";

is $jansson.elems, 4, "jansson.elems on an array";
$jansson[2]:delete;
is $jansson.gist, '[1, 2, "bop"]', "DELETE-POS removed item";
is $jansson.elems, 3, "DELETE-POS updated array length";
is $jansson[2], "bop", "DELETE-POS updated index references";

$jansson[4] = "way over the limit";
is $jansson.gist, '[1, 2, "bop", null, "way over the limit"]', 'array auto-extension with null items';

$jansson.push("three", "four", "five");
is $jansson.gist, '[1, 2, "bop", null, "way over the limit", "three", "four", "five"]', "push multiple values onto array handle";
my $pre-shift-len = $jansson.elems;
my $first-value = $jansson.shift;
is $first-value, 1, "shift got the first item from the array";
is $jansson.elems, $pre-shift-len - 1, "shift reduced the length of the jansson array by 1"; 

my $pre-pop-len = $jansson.elems;
my $last-value = $jansson.pop;
is $last-value, "five", "pop got the last item from the array";
is $jansson.elems, $pre-pop-len - 1, "pop reduced the length of the jansson array by 1"; 

my $pre-unshift-len = $jansson.elems;
$jansson.unshift("a", "b", "c");
is $jansson[0 ... 2], <a b c>, "unshift put multiple items onto the front of the jansson array";
is $jansson.elems, $pre-unshift-len + 3, "unshifting 3 items increased the array len by 3";

done;
