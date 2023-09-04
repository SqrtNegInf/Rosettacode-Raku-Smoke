use ValueList:ver<0.0.1>:auth<zef:lizmat>;

class Tuple:ver<0.0.10>:auth<zef:lizmat> is repr('VMArray') is ValueList {
    multi method gist(Tuple:D:) { 'Tuple.new' ~ callsame }
}

proto sub tuple(|) is export is nodal {*}
multi sub tuple( @args) { Tuple.CREATE.STORE(@args,:INITIALIZE) }
multi sub tuple(+@args) { Tuple.CREATE.STORE(@args,:INITIALIZE) }

=begin pod

=head1 NAME

Tuple - provide an immutable List value type

=head1 SYNOPSIS

=begin code :lang<raku>

use Tuple;

my @a is Tuple = ^10;  # initialization follows single-argument semantics
my @b is Tuple = ^10;

set( @a, @b );  # elems == 1

my $t = tuple(^10);  # also exports a "tuple" sub

=end code

=head1 DESCRIPTION

Raku provides a semi-immutable Positional datatype: List.  A C<List> can
not have any elements added or removed from it.  However, since a list B<can>
contain containers of which the value can be changed, it is not a value type.
So you cannot use Lists in data structures such as C<Set>s, because each List
is considered to be different from any other List, because they are not value
types.

Since Lists are used very heavily internally with the current semantics, it
is a daunting task to make them truly immutable value types.  Hence the
introduction of the C<Tuple> data type.

=head1 IMPLEMENTATION NOTES

In newer versions of Raku and the C<Tuple> class, this class is now simply
a child of the C<ValueList> class (either supplied by the core or by the
C<ValueList> module).

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Tuple .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2018, 2020, 2021, 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
