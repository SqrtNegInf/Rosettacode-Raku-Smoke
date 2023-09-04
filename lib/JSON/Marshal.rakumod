use v6;

=begin pod

=head1 NAME

JSON::Marshal - Make JSON from an Object.

=head1 SYNOPSIS

=begin code
    use JSON::Marshal;

    class SomeClass {
      has Str $.string;
      has Int $.int;
      has Version $.version is marshalled-by('Str');
    }

    my $object = SomeClass.new(string => "string", int => 42, version => Version.new("0.0.1"));


    my Str $json = marshal($object); # -> "{ "string" : "string", "int" : 42, "version" : "0.0.1" }'

=end code

Or with 'opt-in' marshalling:

=begin code
    use JSON::Marshal;
    use JSON::OptIn;

    class SomeClass {
      has Str $.string is json;
      has Int $.int    is json;
      has Str $.secret;
      has Version $.version is marshalled-by('Str');
    }

    my $object = SomeClass.new(secret => "secret", string => "string", int => 42, version => Version.new("0.0.1"));


    my Str $json = marshal($object, :opt-in); # -> "{ "string" : "string", "int" : 42, "version" : "0.0.1" }'

=end code

=head1 DESCRIPTION

This provides a single exported subroutine to create a JSON representation
of an object.  It should round trip back into an object of the same class
using L<JSON::Unmarshal|https://github.com/tadzik/JSON-Unmarshal>.

It only outputs the "public" attributes (that is those with accessors
created by declaring them with the '.' twigil. Attributes without acccessors
are ignored.

If you want to ignore any attributes without a value you can use the
:skip-null adverb to C<marshal>, which will supress the marshalling
of any undefined attributes.  Additionally if you want a finer-grained
control over this behaviour there is a 'json-skip-null' attribute trait
which will cause the specific attribute to be skipped if it isn't defined
irrespective of the C<skip-null>.  C<skip-null> or the C<json-skip-null>
trait is applied to a C<Positional> or C<Associative> attribute this
will suppress the marshalling of an empty list or object attribute.  If
you want to always explicitly suppress the marshalling of an attribute then
the the trait C<json-skip> on an attribute will prevent it being output
in the JSON.

By default B<all> public attributes will be candidates to be marshalled to JSON,
which may not be convenient for all applications (for example only a small
number of attributes should be marshalled in a large class,) so the C<marshal>
provides an C<:opt-in> adverb that inverts the behaviour so that only those
attributes which have one of the traits that control marshalling
(with the exception of C<json-skip>,) will be candidates.  The C<is json> trait
from L<JSON::OptIn|https://github.com/jonathanstowe/JSON-OptIn> can be supplied to
an attribute to mark it for marshalling explicitly, (it is implicit in all the
other traits bar C<json-skip>.)

To allow a finer degree of control of how an attribute is marshalled
an attribute trait C<is marshalled-by> is provided, this can take
either a Code object (an anonymous subroutine,) which should take as an
argument the value to be marshalled and should return a value that can be
completely represented as JSON, that is to say a string, number or boolean
or Nil or a Hash or Array who's values are those things. Alternatively
the name of a method that will be called on the value, the return value
being constrained as above. In the case of the Code argument to the
trait, the supplied subroutine should handle the case of an undefined
value for itself as appropriate, in the case of a method name it will
not be called at all and the attribute will be marshalled as Nil.

You can pass the adverb C<:sorted-keys> to C<marshal> which is in turn
passed on to C<JSON::Fast> to cause the keys to be sorted before the JSON
is created.

By default the JSON produced is I<pretty> (that is newlines and indentation,)
which is nice for humans to read but has a lot of superfluous characters in
it, this can be controlled by passing C<:!pretty> to C<marshal> which is passed
to C<JSON::Fast>


=end pod

use JSON::OptIn;
use JSON::Name:ver<0.0.6+>;

module JSON::Marshal:ver<0.0.23>:auth<github:jonathanstowe> {

    use JSON::Fast:ver(v0.16+);


    role CustomMarshaller does JSON::OptIn::OptedInAttribute {
        method marshal($value, Mu:D $object) {
            ...
        }
    }

    role CustomMarshallerCode does CustomMarshaller {
        has &.marshaller is rw;

        method marshal($value, Mu:D $object) {
            # the dot below is important otherwise it refers
            # to the accessor method
            self.marshaller.($value);
        }
    }

    role CustomMarshallerMethod does CustomMarshaller {
        has Str $.marshaller is rw;
        method marshal($value, Mu:D $type) {
            my $meth = self.marshaller;
            $value.defined ?? $value."$meth"() !! Nil;
        }
    }

    multi sub trait_mod:<is> (Attribute $attr, :&marshalled-by!) is export {
        $attr does CustomMarshallerCode;
        $attr.marshaller = &marshalled-by;
    }

    multi sub trait_mod:<is> (Attribute $attr, Str:D :$marshalled-by!) is export {
        $attr does CustomMarshallerMethod;
        $attr.marshaller = $marshalled-by;
    }

    role SkipNull does JSON::OptIn::OptedInAttribute {
    }

    multi sub trait_mod:<is> (Attribute $attr, :$json-skip-null!) is export {
        $attr does SkipNull;
    }

    # This is a hard skip the attribute will never be emitted.
    role JsonSkip {
    }

    multi sub trait_mod:<is> (Attribute $attr, :$json-skip!) is export {
        $attr does JsonSkip;
    }



    multi sub _marshal(Cool $value, Bool :$skip-null, Bool :$opt-in ) {
        $value;
    }

    multi sub _marshal(Associative:U $, Bool :$skip-null, Bool :$opt-in  --> Nil ) {
        Nil;
    }
    multi sub _marshal(%obj, Bool :$skip-null, Bool :$opt-in  --> Hash ) {
        my %ret;

        for %obj.kv -> $key, $value {
            %ret{$key} = _marshal($value, :$skip-null, :$opt-in);
        }

        %ret;
    }

    multi sub _marshal(Positional:U $, Bool :$skip-null, Bool :$opt-in  --> Nil ) {
        Nil;
    }
    multi sub _marshal(@obj, Bool :$skip-null, Bool :$opt-in  --> Array) {
        my @ret;

        for @obj -> $item {
            @ret.push(_marshal($item, :$skip-null, :$opt-in));
        }
        @ret;
    }

    multi sub _marshal(Mu:U $, Bool :$skip-null, Bool :$opt-in  --> Nil ) {
        Nil;
    }

    multi sub _marshal(Mu:D $obj, Bool :$skip-null, Bool :$opt-in --> Hash ) {
        my %ret;
        my %local-attrs =  $obj.^attributes(:local).map({ $_.name => $_.package });
        for $obj.^attributes -> $attr {
            if %local-attrs{$attr.name}:exists && !(%local-attrs{$attr.name} === $attr.package ) {
                next;
            }
            if $attr.has_accessor {
                my $accessor-name = $attr.name.substr(2); # lose the sigil
                my $name = do if $attr ~~ JSON::Name::NamedAttribute {
                    $attr.json-name;
                }
                else {
                    $accessor-name;
                }
                my $value = $obj.^can($accessor-name) ?? $obj."$accessor-name"() !! $attr.get_value($obj);
                if serialise-ok($attr, $value, $skip-null, $opt-in) {
                    %ret{$name} = do if $attr ~~ CustomMarshaller {
                        $attr.marshal($value, $obj);
                    }
                    else {
                        _marshal($value, :$opt-in);
                    }
                }

            }
        }
        %ret;
    }

    sub serialise-ok(Attribute $attr, Mu $value, Bool $skip-null, Bool $opt-in --> Bool ) {
        my $rc = True;
        if  $attr ~~ JsonSkip || ( $opt-in && ( $attr !~~ JSON::OptIn::OptedInAttribute ) ) {
            $rc = False;
        }
        elsif $skip-null || ( $attr ~~ SkipNull ) {
            if $attr.type ~~ Associative|Positional {
                $rc = ?$value.elems;
            }
            else {
                $rc = $value.defined;
            }
        }
        $rc;
    }

    sub marshal(Any $obj, Bool :$skip-null, Bool :$sorted-keys = False, Bool :$pretty = True, Bool :$opt-in = False --> Str ) is export {
        my $ret = _marshal($obj, :$skip-null, :$opt-in);
        to-json($ret, :$sorted-keys, :$pretty);
    }
}
# vim: expandtab shiftwidth=4 ft=raku
