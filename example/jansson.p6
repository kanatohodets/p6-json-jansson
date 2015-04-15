use v6;
use lib 'lib';
use JSON::Jansson;

my $fh = open "example/small.json";
my $data = $fh.slurp-rest;
my $json = Jansson.new($data);
say $json.refcount;
say $json.type;
say $json[0]<tags>[0 .. 4];
say $json[0].keys;
$json[0]<friends>:delete;
say $json[0].keys;

my @array = (1, 2, 3, 4, [6, 7, 8, 9]);
my $json-array = Jansson.encode(@array);
say $json-array;

$json-array[2] = <a b c d>;
$json-array[4][0] = 'abc';
say $json-array;

# double encoding
say to-json({bloarg => $json-array});

# empty array
my @foo = ();
my $json-foo = Jansson.encode(@foo);
say $json-foo;
$json-foo[5] = '5th index';
say $json-foo;

my $converted = from-json($data);
say $converted;
say $converted[0]<balance>;

# invalid
try {
    my $converted = from-json('[1, 2, 3');
    CATCH {
        when X::JSON::ParseError { say "BLORG IT WAS BAD!" };
    }
}
