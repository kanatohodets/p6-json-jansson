use v6;
use NativeCall;

class JSON::Document { ... };
class JSON::Array { ... };
class JSON::Object { ... };

class JSON is repr('CPointer') {
    class Error is repr('CStruct') {
        has Str $.text;
        has Str $.source;
        has int $.line;
        has int $.column;
        has int $.position;
    }

    class Struct is repr('CStruct') {
        has int8 $.type;
        has int $.refcount;
    }

    sub json_loads(Str, int, Error) returns JSON is native("libjansson") { * }
    sub json_dumps(JSON, int) returns Str is native("libjansson") { * }

    sub json_string_value(JSON) returns Str is native("libjansson") { * }
    sub json_integer_value(JSON) returns int is native("libjansson") { * }
    sub json_real_value(JSON) returns num is native("libjansson") { * }

    sub json_string(Str) returns JSON is native("libjansson") { * }
    sub json_integer(int) returns JSON is native("libjansson") { * }
    sub json_real(num) returns JSON is native("libjansson") { * }
    sub json_true() returns JSON is native("libjansson") { * }
    sub json_false() returns JSON is native("libjansson") { * }
    sub json_null() returns JSON is native("libjansson") { * }

    method new (Str $data) {
        my $err = Error.new();
        # 0x4 for 'JSON_DECODE_ANY'
        json_loads($data, 0x4, $err).specify;
    }

    method specify() {
        given self.type {
            when Associative { JSON::Object.new(json => self) }
            when Positional { JSON::Array.new(json => self) }
            default { self.get-simple-value() }
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
            when Str { JSON::Document.new(json => json_string($value)) }
            when Int { JSON::Document.new(json => json_integer($value)) }
            when Num { JSON::Document.new(json => json_real($value)) }
            when Associative { JSON::Object.encode($value) }
            when Positional { JSON::Array.encode($value) }
            when Bool {
                if ($value) {
                    JSON::Document.new(json => json_true());
                } else {
                    JSON::Document.new(json => json_false());
                }
            }
            when Nil { JSON::Document.new(json => json_null()) }
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
    has $.json handles <refcount gist type>;
}

class JSON::Object is JSON::Document does Associative {
    my class ObjectIter is repr('CPointer') {
        sub json_object_iter(JSON) returns ObjectIter is native("libjansson") { * }
        sub json_object_iter_key(ObjectIter) returns Str is native("libjansson") { * }
        sub json_object_iter_value(ObjectIter) returns JSON is native("libjansson") { * }

        method new(JSON $json) { json_object_iter($json); }

        method key() { json_object_iter_key(self); }

        method value() { json_object_iter_value(self).specify; }

    }

    sub json_object() returns JSON is native("libjansson") { * }
    sub json_object_iter_next(JSON, ObjectIter) returns ObjectIter is native("libjansson") { * }
    sub json_object_get(JSON, Str) returns JSON is native("libjansson") { * }
    # _new indicates that the reference to the new JSON object isn't used after the
    # assignment, so the reference is 'stolen'
    #
    # _nocheck disables jansson's UTF8 validity checking
    # (P6 has that under control)
    sub json_object_set_new_nocheck(JSON, Str, JSON) returns int is native("libjansson") { * }
    sub json_object_del(JSON, Str) returns int is native("libjansson") { * }

    method encode(Associative $object) {
        my $json-object = json_object();
        for $object.kv -> $key, $value {
            my $encoded-value = JSON.encode($value);
            my $result = json_object_set_new_nocheck($json-object, $key, $encoded-value.json);
            die "failure to add $value to Jansson array" if $result == -1;
        }
        return JSON::Object.new(json => $json-object);
    }

    method iter_next($iter) { json_object_iter_next($.json, $iter) }
    method get(Str $key) { json_object_get($.json, $key).specify }

    method at_key(Str $key) {
        self.get($key);
    }

    method delete_key(Str $key) {
        my $ret = json_object_del($.json, $key);
        die "failed to delete key from Jansson object" if $ret == -1;
    }

    method keys() {
        my $iter = ObjectIter.new($.json);
        my @keys := gather while $iter {
            take $iter.key();
            $iter = self.iter_next($iter);
        }
    }

    method values() {
        my $iter = ObjectIter.new($.json);
        my @values := gather while ($iter = self.iter_next($iter)) {
            take $iter.value();
        }
    }

    method kv() {
        my $iter = ObjectIter.new($.json);
        my @pairs := gather while ($iter = self.iter_next($iter)) {
            take $iter.key() => $iter.value();
        }
    }
}

class JSON::Array is JSON::Document does Positional {
    sub json_array() returns JSON is native("libjansson") { * }
    sub json_array_get(JSON, int) returns JSON is native("libjansson") { * }
    sub json_array_size(JSON) returns int is native("libjansson") { * }
    sub json_array_insert_new(JSON, int, JSON) returns int is native("libjansson") { * }
    sub json_array_set_new(JSON, int, JSON) returns int is native("libjansson") { * }
    sub json_array_append_new(JSON, JSON) returns int is native("libjansson") { * }
    sub json_array_remove(JSON, int) returns int is native("libjansson") { * }
    sub json_array_extend(JSON, JSON) returns int is native("libjansson") { * }

    method encode(Positional $array) {
        my $json-array = json_array();
        for $array -> $item {
            my $encoded-item = JSON.encode($item);
            my $result = json_array_append_new($json-array, $encoded-item.json);
            die "failure to add $item to Jansson object" if $result == -1;
        }
        return JSON::Array.new(json => $json-array);
    }

    method get(int $index) { json_array_get($.json, $index).specify }

    method at_pos(int $index) {
        self.get($index);
    }

    method assign_pos(int $index, Mu $item) {
        my $encoded = JSON.encode($item);

        # auto-extend the array, like P6.
        # perhaps a dubious feature? breaks round-tripping because the values
        # go in as 'null' and come out as 'Nil', rather than 'Any'
        if $index > self.len - 1 {
            while self.len - 1 < $index {
                my $ret = json_array_append_new($.json, JSON.encode(Nil).json);
                die "array extension failed in Jansson" if $ret == -1;
            }
        }

        die "index must be > 0" if $index < 0;

        my $ret = json_array_set_new($.json, $index, $encoded.json);
        die "array assignment failed in Jansson" if $ret == -1;
    }

    method delete_pos(int $index) {
        my $result = json_array_remove($.json, $index);
        die "array index deletion failed" if $result == -1;
    }

    method len() {
        json_array_size($.json);
    }

    method enumerate() {
        my @data := gather for ^self.len -> $index {
            take json_array_get($.json, $index).specify;
        }
    }
}

sub to-json($item) is export {
    return JSON.encode($item).gist;
}

sub from-json(Str $json) is export {
    return JSON.new($json);
}
