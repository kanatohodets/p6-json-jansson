use v6;
use lib 'lib';
use JSON::Jansson;

my $fh = open "example/small.json";
my $data = $fh.slurp;
my $json = JSON.new($data);
say $json.refcount;
say $json.type;
say $json[0]<tags>[0 .. 4];
say $json[0].keys;
$json[0].delete_key('friends');
say $json[0].keys;

