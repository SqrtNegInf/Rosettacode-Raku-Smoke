# Use nqp ops as if we are in the core
use nqp;

my class ValueList:ver<0.0.2>:auth<zef:lizmat>
  is IterationBuffer   # get some low level functionality for free
  does Positional      # so we can bind into arrays
  does Iterable        # so it iterates automagically
  is repr('VMArray')   # needed to get nqp:: ops to work on self
{

    multi method WHICH(ValueList:D:) {
        nqp::box_s(
          nqp::concat(
            nqp::if(
              nqp::eqaddr(self.WHAT,ValueList),
              'ValueList|',
              nqp::concat(self.^name,'|')
            ),
            nqp::sha1(
              nqp::join(
                '|',
                nqp::stmts(  # cannot use native str arrays early in setting
                  (my $strings  := nqp::list_s),
                  (my int $i     = -1),
                  (my int $elems = nqp::elems(self)),
                  nqp::while(
                    nqp::islt_i(($i = nqp::add_i($i,1)),$elems),
                    nqp::push_s($strings,nqp::atpos(self,$i).Str)
                  ),
                  $strings
                )
              )
            )
          ),
          ValueObjAt
        )
    }

    proto method new(|) {*}
    multi method new(ValueList: @args) {
        nqp::create(self)!SET-SELF: @args.iterator
    }
    multi method new(ValueList: +@args) {
        nqp::create(self)!SET-SELF: @args.iterator
    }
    method STORE(ValueList:D: \to_store, :$INITIALIZE) {
        $INITIALIZE
          ?? self!SET-SELF(to_store.iterator)
          !! X::Assignment::RO.new(value => self).throw
    }

    method !SET-SELF(\iterator) is raw {
        nqp::until(
          nqp::eqaddr((my \pulled := iterator.pull-one),IterationEnd),
          nqp::push(self, nqp::decont(pulled))
        );

        # make sure we containerize it to prevent it from being slipped
        # into a QuantHash
        my $valuelist = self
    }

    # set up stringification forms
    multi method raku(ValueList:D:) {
        (nqp::eqaddr(self.WHAT,ValueList) ?? 'ValueList' !! self.^name)
          ~ '.new('
          ~ self.List.map(*.raku).join(',')
          ~ ')'
    }
    multi method gist(ValueList:D:) { self.List.gist }
    multi method Str(ValueList:D:)  { self.raku }

    method list() { self.List }
    method FLATTENABLE_LIST() is implementation-detail { self }

    multi method roll(ValueList:D: |c) { self.List.roll: |c }
    multi method pick(ValueList:D: |c) { self.List.pick: |c }

    # coercions
    multi method Capture(ValueList:D:) {
        nqp::p6bindattrinvres(nqp::create(Capture),Capture,'@!list',self)
    }

    # methods that are not allowed on immutable things
    BEGIN for <
      ASSIGN-POS BIND-POS push append pop shift unshift prepend
    > -> $method {
        ValueList.^add_method: $method, method (ValueList:D: |) {
            X::Immutable.new(:$method, typename => self.^name).throw
        }
    }
}

sub EXPORT() {
    CORE::.EXISTS-KEY('ValueList')
      ?? Map.new
      !! Map.new( (ValueList => ValueList) )
}

=begin pod

=head1 NAME

ValueList - Provide an immutable List value type

=head1 SYNOPSIS

=begin code :lang<raku>

use ValueList;

my @a is ValueList = ^10;  # initialization follows single-argument semantics
my @b is ValueList = ^10;

set( @a, @b );  # elems == 1

=end code

=head1 DESCRIPTION

The functionality provided by this module, will be provided in
language level 6.e and higher.  If an implementation of ValueList
is already available, loading this module becomes a no-op.

Raku provides a semi-immutable Positional datatype: List.  A C<List> can
not have any elements added or removed from it.  However, since a list B<can>
contain containers of which the value can be changed, it is not a value type.
So you cannot use Lists in data structures such as C<Set>s, because each List
is considered to be different from any other List, because they are not value
types.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/ValueList .
Comments and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
