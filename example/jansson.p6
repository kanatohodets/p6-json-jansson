use v6;
use lib 'lib';
use JSON::Jansson;

my $fh = open "example/small.json";
my $data = $fh.slurp;
my $json = JSON.new($data);
say $json.refcount;
say $json.type;

# there's a race somewhere.
my $foo = $json.get(0);
say $foo;
my $tags = $foo.get("tags");
say $tags;
my $first = $tags.get(0);
say $first;

say "refcounts: ";
say $_.refcount for ($json, $foo, $tags, $first);
