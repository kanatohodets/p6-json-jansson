use v6;
use NativeCall;

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

    method new (Str $data) {
        my $err = Error.new();
        # 0x4 for 'JSON_DECODE_ANY'
        json_loads($data, 0x4, $err).specify;
    }

    method specify() {
        given self.type {
            when Hash { JSON::Object.new(json => self) }
            when Array { JSON::Array.new(json => self) }
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
        return True if $type ~~ Hash or $type ~~ Array;
        return False;
    }

    method get-simple-value() {
        given self.type {
            when Str { json_string_value(self) }
            when Int { json_integer_value(self) }
            when Real { json_real_value(self) }
            when True { True }
            when False { False }
            when Nil { Nil }
        }
    }

    method type() {
        my $struct = nativecast(Struct, self);
        given $struct.type {
            when 0 { Hash }
            when 1 { Array }
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

    sub json_object_iter_next(JSON, ObjectIter) returns ObjectIter is native("libjansson") { * }
    sub json_object_get(JSON, Str) returns JSON is native("libjansson") { * }
    sub json_object_del(JSON, Str) returns int is native("libjansson") { * }

    method iter_next($iter) { json_object_iter_next($.json, $iter) }
    method get(Str $key) { json_object_get($.json, $key).specify }

    method at_key(Str $key) {
        self.get($key);
    }

    method delete_key(Str $key) {
        my $ret = json_object_del($.json, $key);
        return True if $ret == 0;
        return False;
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
    sub json_array_get(JSON, int) returns JSON is native("libjansson") { * }
    sub json_array_size(JSON) returns int is native("libjansson") { * }
    sub json_array_insert_new(JSON, int, JSON) returns int is native("libjansson") { * }
    sub json_array_set_new(JSON, int, JSON) returns int is native("libjansson") { * }
    sub json_array_append_new(JSON, JSON) returns int is native("libjansson") { * }
    sub json_array_remove(JSON, int) returns int is native("libjansson") { * }
    sub json_array_extend(JSON, JSON) returns int is native("libjansson") { * }

    method get(int $index) { json_array_get($.json, $index).specify }

    method at_pos(int $index) {
        self.get($index);
    }

    method assign_pos(int $index, Mu $item) {
        die 'NYI';
        my $new-json = JSON.encode($item);
        if $index < self.len {
            my $ret = json_array_set_new($.json, $index, $new-json);
            return True if $ret == 0;
        }
        return False;
    }

    method len() {
        json_array_size($.json);
    }

    method enumerate() {
        my @data := gather for ^self.len -> $index {
            take json_array_get($.json, $index).specify;
        }
        @data.eager;
    }
}
