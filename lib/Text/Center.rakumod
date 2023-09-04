use v6.c;
unit module Text::Center:ver<0.0.2>;

sub center ($text, Int $width = 79, :$fill = ' ') is export {
    my $pad = $width - 2 - $text.Str.chars;
    my $space = $pad < 0 ?? '' !! ' ';
    my $centered = $fill x ($pad / 2).ceiling ~ $space ~ $text ~ $space ~ $fill x ($pad / 2).floor;
    $centered.chars < $width ?? ("$centered ") !! $centered
}

=begin pod

=head1 NAME

Text::Center  - Easy centering of text fields

[![Build Status](https://travis-ci.org/thundergnat/Text-Center.svg?branch=master)](https://travis-ci.org/thundergnat/Text-Center)

=head1 SYNOPSIS

=begin code :lang<perl6>

use Text::Center;

say 'Raku'.&center; # Center in a 79 columns by default, space padded by default
#                                      Raku

say 'Raku'.&center(20); # Center in 20 columns, space padded
#        Raku

say 'Raku'.&center(30, :fill('=')); # Center in 30 columns, equal sign padded
#============ Raku ============

=end code

=head1 DESCRIPTION

Easily center text in a configurable field width (default 79). Pad with spaces
by default but may substitute some other character if desired. Will leave a
single space on either side of the text unless the text is too large to fit into
the field width. In that case, just returns the text unaltered.

Exports a single subroutine:

    center( $text, $width = 79, :fill(' ') )

where

    $text is the text to be centered.

    $width (optional) is the field width to center within, default 79

    :fill (optional) is the fill character to use, default ' ' (space)

=head1 AUTHOR

thundergnat aka Steve Schulze

=head1 COPYRIGHT AND LICENSE

Copyright 2020 thundergnat

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
