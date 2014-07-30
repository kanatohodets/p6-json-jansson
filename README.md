#JSON::Jansson

This is a basic Perl 6 binding to libjansson: a C library for manipulating JSON data.

Don't use it yet! Some intersection of NativeCall, jansson's refcounting, and
my weak C chops are causing major, race-y issues.

### SYNOPSIS

    use JSON::Jansson;
    my $json = JSON.new('{"foo": 42}');
    say $json.get("foo");
    say $json.type; # (Hash)
    #???

### TODO

0. hunt down the race condition that's causing things to be undefined.
1. manipulate JSON as a p6 data structure
2. don't leak memory
3. encoding
4. tests

### LICENSE

Artistic License 2.0

### SEE ALSO

[JSON::Tiny](github.com/moritz/json)
