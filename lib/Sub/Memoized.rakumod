# Create the identification string for the capture to serve as key
my sub fingerprint(Capture:D $capture --> Str:D) {
    my str @parts = $capture.list.map: *<>.WHICH.Str;
    @parts.push('|');  # don't allow positionals to bleed into nameds
    for $capture.hash -> $pair {
        @parts.push( $pair.key );  # key is always a string with nameds
        @parts.push( $pair.value<>.WHICH.Str );
    }
    @parts.join('|')
}

# Perform the actual wrapping of the sub to have it memoized
my sub memoize(\r, \cache --> Nil) {
    r.wrap(-> |c {
        my $key := fingerprint(c);
        cache.EXISTS-KEY($key)
          ?? cache.AT-KEY($key)
          !! cache.BIND-KEY($key,callsame);
    });
}

# Handle the "is memoized" / is memoized(Bool:D) cases
multi sub trait_mod:<is>(Sub:D \r, Bool:D :$memoized! --> Nil) is export {
    if $memoized {
        my $name = r.^name;
        memoize(r, {});
        r.WHAT.^set_name("$name\(memoized)");
    }
}

# Handle the "is memoized(my %h)" case
multi sub trait_mod:<is>(Sub:D \r, Hash:D :$memoized! --> Nil) is export {
    my $name = r.^name;
    memoize(r, $memoized<>);
    r.WHAT.^set_name("$name\(memoized)");
}

=begin pod

=head1 NAME

Sub::Memoized - trait for memoizing calls to subroutines

=head1 SYNOPSIS

  use Sub::Memoized;

  sub a($a,$b) is memoized {
      # do some expensive calculation
  }

  sub b($a, $b) is memoized( my %cache ) {
      # do some expensive calculation with direct access to cache
  }

  use Hash::LRU;
  sub c($a, $b) is memoized( my %cache is LRU( elements => 2048 ) ) {
      # do some expensive calculation, keep last 2048 results returned
  }

=head1 DESCRIPTION

Sub::Memoized provides a C<is memoized> trait on C<Sub>routines as an easy
way to cache calculations made by that subroutine (assuming a given set of
input parameters will always produce the same result).

Optionally, you can specify a hash that will serve as the cache.  This
allows later access to the generated results.  Or you can specify a specially
crafted hash, such as one made with C<Hash::LRU>.

Please note that if you do not use a store that is thread-safe, the memoization
will not be thread-safe either.  This is the default.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Sub-Memoized . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2018, 2020, 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=end pod

# vim: ft=perl6 expandtab sw=4
