#JSON::Jansson

This is a basic Perl 6 binding to libjansson: a C library for manipulating JSON data.

Still pretty rough! There's no API for dumping JSON into a native P6 data
structure yet, so at the moment the best you can do is index into the JSON blob
using `get`. Also nothing for encoding data structures into JSON.

### SYNOPSIS

    use JSON::Jansson;
    my $object-json = JSON.new('{"foo": 42}');
    say $json<foo>; # 42
    say $json.type; # (Hash)
    my $array-json = JSON.new('["quux", 4, true]');
    say $array-json[0]; # "quux"
    #???

### TODO

0. encoding p6 data structures into libjansson JSON objects
1. manipulate JSON as a p6 data structure (partly done, needs ^ for assignment)
2. don't leak memory (decref JSON pieces that are removed)
3. option to copy all the data out of jansson land into p6 structures, rather
than manipulating jansson JSON objects via p6.
4. tests


### LICENSE

Artistic License 2.0

### SEE ALSO

[JSON::Tiny](github.com/moritz/json)
