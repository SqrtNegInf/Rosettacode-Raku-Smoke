unit module List::Allmax;

sub all-max (*@list, Callable :&by = {$_}, :$k = False) is export  {
    if @list.is-lazy { X::Cannot::Lazy.new(action =>'all-max').throw }
    my @max-list;
    my $max = @list[0];
    my &comp = { &by($^a) cmp &by($^b) }
    if $k {
        for ^@list {
            if comp(@list[$_], $max) == 0 {
                @max-list.push: $_;
            } elsif comp(@list[$_], $max) > 0 {
                $max = @list[$_];
                @max-list = $_
            }
        }
    } else {
        for @list {
            if comp($_, $max) == 0 {
                @max-list.push: $_;
            } elsif comp($_, $max) > 0 {
                $max = $_;
                @max-list = $_
            }
        }
    }
    @max-list
}

sub all-min (*@list, Callable :&by = {$_}, :$k = False) is export  {
    if @list.is-lazy { X::Cannot::Lazy.new(action =>'all-min').throw }
    my @min-list;
    my $min = @list[0];
    my &comp = { &by($^a) cmp &by($^b) }
    if $k {
        for ^@list {
            if comp(@list[$_], $min) == 0 {
                @min-list.push: $_;
            } elsif comp(@list[$_], $min) < 0 {
                $min = @list[$_];
                @min-list = $_
            }
        }
    } else {
        for @list {
            if comp($_, $min) == 0 {
                @min-list.push: $_;
            } elsif comp($_, $min) < 0 {
                $min = $_;
                @min-list = $_
            }
        }
    }
    @min-list
}


=begin pod

=head1 NAME

List::Allmax - Find all of the maximum or minimum elements of a list.

=head1 SYNOPSIS

=begin code :lang<raku>

use List::Allmax;

say (^20).roll(50).&all-max;     # values

say (^20).roll(50).&all-min: :k; # keys

say [1,2,3,4,5,5,4,3,2,1,2,2,5,4,4].classify({$_}).sort.List.&all-max( :by(+*.value) );
# [2 => [2,2,2,2], 4 => [4,4,4,4]]

=end code

=head1 DESCRIPTION

Raku provides C<max> and C<min> routines to find the maximum or minimum elements of a
list. If there is more than one value that evaluates to the maximum, (minimum)
only the first is reported, no matter how many there may be. This module
provides a remedy for that.

Provides the routines C<all-max()> and C<all-min()> that return _all_ of the elements
that evaluate to maximum or minimum value.

Similar to the built-ins, you may request either a list of values or a list of
indicies (keys) where those values are located.

If you want to compare based on something other than the values of the
individual elements, supply a named C<:by()> Callable block to be used as an
evaluator. Defaults to C<{$_}> (self).


Note: Only operates on Positional objects. If want to use it on a Hash or some
other Associative type, coerce to a Listy type object first.


=head1 AUTHOR

Stephen Schulze (aka thundergnat <thundergnat@comcast.net>)

=head1 COPYRIGHT AND LICENSE

Copyright 2023 thundergnat

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
