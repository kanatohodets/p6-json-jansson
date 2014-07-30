use v6;
use NativeCall;

class Error is repr('CStruct') {
    has Str $.text;
    has Str $.source;
    has int $.line;
    has int $.column;
    has int $.position;
}

class JSONStruct is repr('CStruct') {
    has int8 $.type;
    has int $.refcount;
}

class JSON is repr('CPointer') {
    sub json_loads(Str, int, Error) returns JSON is native("libjansson") { * }
    sub json_dumps(JSON, int) returns Str is native("libjansson") { * }
    sub json_decref(JSON) is native("libjansson") { * }
    sub json_array_get(JSON, int) returns JSON is native("libjansson") { * }
    sub json_object_get(JSON, Str) returns JSON is native("libjansson") { * }

    method new (Str $data) {
        my $err = Error.new();
        # 0x4 for 'JSON_DECODE_ANY'
        my $json = json_loads($data, 0x4, $err);
    }

    method get ($key) {
        given self.type {
            when Hash { json_object_get(self, $key) }
            when Array { json_array_get(self, $key) }
        }
    }

    method refcount() {
        my $struct = nativecast(JSONStruct, self);
        $struct.refcount;
    }

    # 0x200 for 'JSON_ENCODE_ANY'
    method gist() { json_dumps(self, 0x200); }

    method type() {
        my $struct = nativecast(JSONStruct, self);
        given $struct.type {
            # object
            when 0 { Hash }
            when 1 { Array }
            when 2 { Str }
            when 3 { Int }
            when 4 { Real }
            # true
            when 5 { Bool }
            # false
            when 6 { Bool }
            # null
            when 7 { Mu }
        }
    }
}
