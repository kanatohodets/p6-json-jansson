use v6;
use NativeCall;

class JSON::Document { ... };
class JSON::Array { ... };
class JSON::Object { ... };

class Jansson is repr('CPointer') {
    my class X::JSON::ParseError is Exception { }

    my class Error is repr('CStruct') {
        has str $.text;
        has str $.source;
        has int $.line;
        has int $.column;
        has int $.position;
    }

    my class Struct is repr('CStruct') {
        has int8 $.type;
        has int $.refcount;
    }

    sub json_loads(Str, int, Error) returns Jansson is native("libjansson") { * }
    sub json_dumps(Jansson, int) returns Str is native("libjansson") { * }

    sub json_string_value(Jansson) returns Str is native("libjansson") { * }
    sub json_integer_value(Jansson) returns int is native("libjansson") { * }
    sub json_real_value(Jansson) returns num is native("libjansson") { * }

    sub json_string(Str) returns Jansson is native("libjansson") { * }
    sub json_integer(int) returns Jansson is native("libjansson") { * }
    sub json_real(num) returns Jansson is native("libjansson") { * }
    sub json_true() returns Jansson is native("libjansson") { * }
    sub json_false() returns Jansson is native("libjansson") { * }
    sub json_null() returns Jansson is native("libjansson") { * }

    method new (Str $data) {
        my $err = Error.new();
        # 0x4 for 'JSON_DECODE_ANY'
        my $result = json_loads($data, 0x4, $err);
        # really we should take a peek at the contents of 'err' here,
        # but that tends to segfault, so check for truthiness of $result (which
        # is a falsy, empty type object if json_loads failed)
        die X::JSON::ParseError.new(payload => "failed to parse JSON -- please check that the input string is valid") if !$result;
        $result.specify;
    }

    method specify() {
        given self.type {
            when Associative { JSON::Object.new(jansson => self) }
            when Positional { JSON::Array.new(jansson => self) }
            default { JSON::Document.new(jansson => self) }
        }
    }

    method refcount() {
        my $struct = nativecast(Struct, self);
        $struct.refcount;
    }

    # 0x200 for 'JSON_ENCODE_ANY'
    method gist() { json_dumps(self, 0x200); }

    method is-complex() {
        my $type = self.type;
        return True if $type ~~ Associative or $type ~~ Positional;
        return False;
    }

    method get-simple-value() {
        given self.type {
            when Str { json_string_value(self) }
            when Int { json_integer_value(self) }
            when Real { json_real_value(self) }
            when Bool::True { True }
            when Bool::False { False }
            when Nil { Nil }
        }
    }

    method encode(Mu $value) {
        given $value {
            # no double encoding
            when JSON::Document { $value }
            when Str { JSON::Document.new(jansson => json_string($value)) }
            when Int { JSON::Document.new(jansson => json_integer($value)) }
            when Num { JSON::Document.new(jansson => json_real($value)) }
            when Associative { JSON::Object.encode($value) }
            when Positional { JSON::Array.encode($value) }
            when Bool {
                if ($value) {
                    JSON::Document.new(jansson => json_true());
                } else {
                    JSON::Document.new(jansson => json_false());
                }
            }
            when Nil { JSON::Document.new(jansson => json_null()) }
            default { die "cannot encode a value of type {$value.WHAT.perl}"}
        }

    }

    method type() {
        my $struct = nativecast(Struct, self);
        given $struct.type {
            when 0 { Associative }
            when 1 { Positional }
            when 2 { Str }
            when 3 { Int }
            when 4 { Real }
            when 5 { Bool::True }
            when 6 { Bool::False }
            when 7 { Nil }
        }
    }
}

class JSON::Document {
    has $.jansson handles <refcount gist type is-complex get-simple-value>;
    method val() {
        return self.get-simple-value if !self.is-complex;
        return self;
    }
}

class JSON::Object is JSON::Document does Associative {
    my class ObjectIter is repr('CPointer') {
        sub json_object_iter(Jansson) returns ObjectIter is native("libjansson") { * }
        sub json_object_iter_key(ObjectIter) returns Str is native("libjansson") { * }
        sub json_object_iter_value(ObjectIter) returns Jansson is native("libjansson") { * }

        method new(Jansson $json) { json_object_iter($json); }

        method key() { json_object_iter_key(self); }

        method value() { json_object_iter_value(self).specify; }

    }

    sub json_object() returns Jansson is native("libjansson") { * }
    sub json_object_iter_next(Jansson, ObjectIter) returns ObjectIter is native("libjansson") { * }
    sub json_object_get(Jansson, Str) returns Jansson is native("libjansson") { * }
    # _new indicates that the reference to the new Jansson object isn't used after the
    # assignment, so the reference is 'stolen'
    #
    # _nocheck disables jansson's UTF8 validity checking
    # (P6 has that under control)
    sub json_object_set_new_nocheck(Jansson, Str, Jansson) returns int is native("libjansson") { * }
    sub json_object_del(Jansson, Str) returns int is native("libjansson") { * }

    method encode(Associative $object) {
        my $json-object = json_object();
        for $object.kv -> $key, $value {
            my $encoded-value = Jansson.encode($value);
            my $result = json_object_set_new_nocheck($json-object, $key, $encoded-value.jansson);
            die "failure to add $value to Jansson array" if $result == -1;
        }
        return JSON::Object.new(jansson => $json-object);
    }

    method iter_next($iter) { json_object_iter_next($.jansson, $iter) }
    method get(Str $key) { json_object_get($.jansson, $key).specify }

    method at_key(Str $key) {
        self.get($key).val;
    }

    method delete_key(Str $key) {
        my $ret = json_object_del($.jansson, $key);
        die "failed to delete key from Jansson object" if $ret == -1;
    }

    method keys() {
        my $iter = ObjectIter.new($.jansson);
        my @keys := gather while $iter {
            take $iter.key();
            $iter = self.iter_next($iter);
        }
    }

    method values() {
        my $iter = ObjectIter.new($.jansson);
        my @values := gather while $iter {
            take $iter.value().val;
            $iter = self.iter_next($iter);

        }
    }

    method kv() {
        my $iter = ObjectIter.new($.jansson);
        my @pairs := gather while $iter {
            take $iter.key(), $iter.value().val;
            $iter = self.iter_next($iter);
        }
    }
}

class JSON::Array is JSON::Document does Positional {
    sub json_array() returns Jansson is native("libjansson") { * }
    sub json_array_get(Jansson, int) returns Jansson is native("libjansson") { * }
    sub json_array_size(Jansson) returns int is native("libjansson") { * }
    sub json_array_insert_new(Jansson, int, Jansson) returns int is native("libjansson") { * }
    sub json_array_set_new(Jansson, int, Jansson) returns int is native("libjansson") { * }
    sub json_array_append_new(Jansson, Jansson) returns int is native("libjansson") { * }
    sub json_array_remove(Jansson, int) returns int is native("libjansson") { * }
    sub json_array_extend(Jansson, Jansson) returns int is native("libjansson") { * }

    method encode(Positional $array) {
        my $json-array = json_array();
        for $array -> $item {
            my $encoded-item = Jansson.encode($item);
            my $result = json_array_append_new($json-array, $encoded-item.jansson);
            die "failure to add $item to Jansson object" if $result == -1;
        }
        return JSON::Array.new(jansson => $json-array);
    }

    method get(int $index) { json_array_get($.jansson, $index).specify }

    method at_pos(int $index) {
        self.get($index).val;
    }

    method assign_pos(int $index, Mu $item) {
        my $encoded = Jansson.encode($item);

        # auto-extend the array, like P6.
        # perhaps a dubious feature? breaks round-tripping because the values
        # go in as 'null' and come out as 'Nil', rather than 'Any'
        if $index > self.len - 1 {
            while self.len - 1 < $index {
                my $ret = json_array_append_new($.jansson, Jansson.encode(Nil).jansson);
                die "array extension failed in Jansson" if $ret == -1;
            }
        }

        die "index must be > 0" if $index < 0;

        my $ret = json_array_set_new($.jansson, $index, $encoded.jansson);
        die "array assignment failed in Jansson" if $ret == -1;
    }

    method delete_pos(int $index) {
        my $result = json_array_remove($.jansson, $index);
        die "array index deletion failed" if $result == -1;
    }

    method len() {
        json_array_size($.jansson);
    }

    method enumerate() {
        my @data := gather for ^self.len -> $index {
            take json_array_get($.jansson, $index).specify.val;
        }
    }
}

sub to-json($item) is export {
    return Jansson.encode($item).gist;
}

sub convert($item) {
    return $item if !$item.^parents.grep(JSON::Document);

    my $json = $item;
    if $json.type ~~ Positional {
        my $list = [];
        for $json.enumerate() -> $value {
            $list.push(convert($value));
        }
        return $list;
    } elsif $json.type ~~ Associative {
        my $hash = {};
        for $json.kv -> $key, $value {
            $hash{$key} = convert($value);
        }
        return $hash;
    }
}

sub from-json(Str $json) is export {
    my $decoded = Jansson.new($json);
    return convert($decoded);
}

sub jansson-from-json(Str $json) is export {
    return Jansson.new($json);
}
