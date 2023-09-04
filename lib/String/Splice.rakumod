use v6.c;
unit module Str::Splice:ver<0.0.3>:auth<github:thundergnat>;
use nqp;

role Splice {
    multi method splice (Str:D: Int(Real) $start, Int(Real) $chars, Str(Any) $add = '' --> Str) {
        fail "Start offset ($start) must be positive" if $start < 0;
        fail "Characters ($chars) must be positive" if $chars < 0;
        splice-it(self, $start, $chars, $add)
    }

    multi method splice (Str:D: Int(Real) $start, Str $add = '' --> Str) {
        fail "Start offset ($start) can not be negative" if $start < 0;
        fail "Last parameter ($add) must be a string" unless $add.^name ~~ Str;
        splice-it(self, $start, 0, $add)
    }

    multi method splice (Str:D: WhateverCode $w, Int(Real) $chars, Str(Any) $add = '' --> Str) {
        fail "Last parameter ($add) must be a string" unless $add.^name ~~ Str;
        splice-it(self, (self.chars).&($w), $chars, $add)
    }

    multi method splice (Str:D: WhateverCode $w, Str $add = '' --> Str) {
        fail "Last parameter ($add) must be a string" unless $add.^name ~~ Str;
        splice-it(self, (self.chars).&($w) max 0, 0, $add)
    }
}

proto sub splice (Str(Any) $, |c) is pure {*};

multi splice (Str(Any) $str, Int(Real) $start, Int(Real) $chars, Str(Any) $add = '' --> Str) is export {
    fail "Start offset ($start) can not be negative" if $start < 0;
    fail "Characters ($chars) must be positive" if $chars < 0;
    splice-it($str, $start, $chars, $add)
}

multi splice (Str(Any) $str, Int(Real) $start, Str $add = '' --> Str) is export {
    fail "Start offset ($start) can not be negative" if $start < 0;
    fail "Last parameter ($add) must be a string" unless $add.^name ~~ Str;
    splice-it($str, $start, 0, $add)
}

multi splice (Str(Any) $str, WhateverCode $w, Int(Real) $chars, Str(Any) $add = '' --> Str) is export {
    fail "Characters ($chars) must be positive" if $chars < 0;
    splice-it($str, ($str.chars).&($w), $chars, $add)
}

multi splice (Str(Any) $str, WhateverCode $w, Str $add = '' --> Str) is export {
    fail "Last parameter ($add) must be a string" unless $add.^name ~~ Str;
    splice-it($str, ($str.chars).&($w) max 0, 0, $add)
}

sub splice-it ($str, $start, $chars = 0, $add = '') {
    $str.chars < $start ??
    ($str ~  ' ' x $start - $str.chars ~ $add) !!
    (nqp::substr($str, 0, $start) ~ $add ~ nqp::substr($str, $start + $chars))
}


=begin pod

=head1 Name

[![Build Status](https://travis-ci.org/thundergnat/String-Splice.svg?branch=master)](https://travis-ci.org/thundergnat/String-Splice)

String::Splice - splice, but for Strings instead of Arrays

=head1 Synopsis

=begin code :lang<perl6>

use String::Splice;

say 'Perl 6 is awesome'.&splice(0, 6, 'Raku');
# Raku is awesome

say splice('This is Rakudo', *-2, 2);
# This is Raku

say "Tonight I'm gonna party like it's 1999"
  .&splice(18, 5, 'program').&splice(*-4, 2, 20);
# Tonight I'm gonna program like it's 2099

=end code

=head1 Description

String::Splice is intended to give a simple interface to slicing and dicing
Strings  much in the same way that CORE Array.splice makes it easy to slice and
dice Arrays.

Works very similarly on strings as the CORE splice works on Arrays.

Available as both a method (augmenting strings) or as a subroutine (that
primarily operates on strings).

=begin code :lang<perl6>

multi sub    splice($String:D, $start, $chars?, $replacement = '' --> Str)

=end code

The splice routine may be called with either three or four parameters.

Need to supply a defined string to operate on, a starting point (in chars),
optionally the number of chars to affect, and an optional replacement string
(defaults to ''). The starting point may be a positive integer, any Real numeric
value that can be coerced to a positive integer, or a WhateverCode that will
offset from the string end.

Use a WhateverCode if you want to modify a string some set offset from the end
of an unknown length string rather than from the start.

C<'Be home by 6:00PM'.&splice(*-2, 1, 'A')>
C<# Be home by 6:00AM>

You may supply a start point larger than the string and the string will be
padded with spaces to achieve that starting point.

C<splice('Raku', 9, 'rocks')> is valid, as is C<splice('Raku', *+5, 'rocks')>

The major difference in how String.splice differs from Array.splice is in that
the starting position does not default to zero. It must be given.

Three parameter splice is mostly useful as an "insert" operation. You supply a
receiving string, an "insert position" and a string to insert. The returned
string will be the receiving string with the insertion string added at the start
position. Technically, you could do a two argument splice, supplying a receiving
string and a start position, and it will then insert a blank string at the start
position, but that's kind-of pointless.

Four parameter splice is useful for remove or replace operations. You supply a
receiving string, an "insert position", the number of characters to replace, and
a string to insert. Remove portions of the string by replacing the substring
with a blank, or change the string by replacing the substring with a different
string.

The replace parameter does not necessarily need to be a string. Anything that
may be coerced to a string may be supplied and will likely work as expected.
When using 3 parameter splice: (String, start, insert), insert _must_ be a
string to disambiguify the signature to the dispatcher. You can always use the
four parameter form with a 0 chars parameter to get the automatic coercion.

=head1 Off topic musings

I debated whether it was a good idea call this method/routine splice as splice
is already used in core. The existing splice only works on Arrays and Bufs
though, so there isn't much likelihood of confusion. I kicked around a few other
name options (slice? dice?, nah, slice is already in use and not a very similar
operation. dice maybe, but no historical corollation, and I really like the
strange consistency between Array splice and String splice.)

Honestly, I am slightly surprised that something like this does not already
exist in CORE what with Perls reputation as a text wrangling utility. I would be
quite willing to contribute the idea and code if there were interest in folding
it in. Better to start out as a module though to prove it out.

=head1 Author

Steve Schulze (thundergnat)

=head1 Copyright and License

Copyright 2020 Steve Schulze

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
