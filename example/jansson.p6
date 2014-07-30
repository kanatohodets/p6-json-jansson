use v6;
use lib 'lib';
use JSON::Jansson;

my $fh = open "example/small.json";
my $data = $fh.slurp;
my $json = JSON.new($data);
say $json.refcount;
say $json.type;

# there's a race somewhere.
my $foo = $json.get(0).get("tags").get(2);
say $foo;
say $foo for 1 .. 15;

