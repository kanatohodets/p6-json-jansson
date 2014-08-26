#JSON::Jansson

This is a basic Perl 6 binding to libjansson: a C library for manipulating JSON data.

Still pretty rough! Feedback/issues/pull reqs welcome.

While JSON::Jansson tends to be much faster than JSON::Tiny (native libraries
are cheating...), it is still a tad slower than than Perl 5's JSON::XS.

For a quick example, on a 180mb JSON blob, JSON::XS parsed it in about 4 seconds,
while generating a Jansson handle (`from-json($data, True)`) took about 13
seconds.

NB: The usual disclaimers about lies and benchmarks apply -- these are an ad-hoc
comparisons run off a busy laptop.

### SYNOPSIS

    use JSON::Jansson;
    # decoding has two options
    my $json-for-import = '{"foo": ["a", 42, {"bar": "deep nesting"}]}';

    # 1) load into Perl 6 data structure (slower, but easier to work with)
    my %object = from-json($json-for-import);

    # 2) access the data via a jansson handle (faster, but might not behave
    # exactly like you expect an array or hash to behave).
    my $jansson-handle = from-json($json-for-import, True);

    # encoding
    my $json-for-export = to-json({foobar => [99, "lollipop"]});

### TODO

0. don't leak memory (decref JSON pieces that are DESTROYed) -- made trickier by jansson using macros to define the decref functions, which NativeCall can't see.
1. tests

### LICENSE

Artistic License 2.0

### CREDITS

* The wonderful NativeCall module 
* FROGGS/timotimo for answering some questions on #perl6.
* colomon for spotting bugs by adding tests

### SEE ALSO

[JSON::Tiny](github.com/moritz/json)
