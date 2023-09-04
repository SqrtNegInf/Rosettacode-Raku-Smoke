unit module Prime::Factor:ver<0.4.0>:auth<github:thundergnat>;

multi prime-factors ( Int $n where * > 1 ) is export {
    return $n if $n.is-prime;
    my $factor = find-factor( $n );
    sort flat prime-factors( $factor ), prime-factors( $n div $factor );
}

multi prime-factors ( Int $n where * < 2 ) is export { () };

multi prime-factors (Str $n) is export {
    if $n.Numeric !~~ Failure {
        samewith (+$n).narrow;
    } else {
        fail "prime-factors() not defined for non Integer strings."
    }
}

multi prime-factors (Any $n) is export {
    fail "prime-factors() not defined for non Integer parameters."
}

# use Pollard's rho algorithm to speed factorization
# See Wikipedia "Pollard's rho algorithm" and
# Damian Conways "On the Shoulders of Giants" presentation from YAPC::NA 2016
sub find-factor ( Int $n, $constant = 1 ) {
    return 2 unless $n +& 1;
    if (my $gcd = $n gcd 6541380665835015) > 1 { # magic number: [*] primes 3 .. 43
        return $gcd if $gcd != $n
    }
    my $x      = 2;
    my $rho    = 1;
    my $factor = 1;
    while $factor == 1 {
        $rho = $rho +< 1;
        my $fixed = $x;
        my int $i = 0;
        while $i < $rho {
            $x = ( $x * $x + $constant ) % $n;
            $factor = ( $x - $fixed ) gcd $n;
            last if 1 < $factor;
            $i = $i + 1;
        }
    }
    $factor = find-factor( $n, $constant + 1 ) if $n == $factor;
    $factor;
}

#`[

Determined by testing, below ~250000, on average, divisors is faster by trial
division, above ~250000, on average, is faster by factoring.

]
constant breakpoint = 250000;

constant SMALL = 1 ..^ breakpoint;
constant BIG   = breakpoint .. *;

multi divisors (1, :s(:$sort) = False) is export { (1,) }

multi divisors (Int \N where BIG, :s(:$sort) = False) is export {
    return (1,N) if N.is-prime;
    my \factors = bag prime-factors(N);
    my \these   = factors.keys xx *;
    my \upto    = [X] factors.map: { 0 .. .value }
    +factors.keys == 1
    ?? $sort
      ?? flat sort (these «**« upto)
      !! flat (these «**« upto)
    !! $sort
      ?? flat sort ([×] .list for these «**« upto)
      !! flat ([×] .list for these «**« upto)
}

multi divisors (Int \N where SMALL, :s(:$sort) = False) is export {
    return (1,N) if N.is-prime;
    my \sqrrt = (sqrt N).narrow;
    my \lower = (2 ..^ sqrrt.ceiling).grep: N %% *;
    $sort
      ?? flat 1, (sort flat lower, (Slip(sqrrt) if sqrrt ~~ Int), N «div« lower), N
      !! flat 1, lower, (Slip(sqrrt) if sqrrt ~~ Int), N «div« lower, N
}

multi divisors (Int \N where * < 1, :s(:$sort) = False) is export { () }

multi divisors (Str $n, :s(:$sort) = False) is export {
    if $n.Numeric !~~ Failure {
        samewith (+$n).narrow, :sort($sort);
    } else {
        fail "divisors() not defined for non Integer strings."
    }
}


multi divisors (Any $n, :s(:$sort) = False) is export {
    fail "divisors() not defined for {$n.^name} parameters. Coerce to Int before calling.";
}

multi proper-divisors (1, :s(:$sort) = False) is export { () }

multi proper-divisors (Int \N where BIG, :s(:$sort) = False) is export {
    return (1,) if N.is-prime;
    my \factors = bag prime-factors(N);
    my \these   = factors.keys xx *;
    my \upto    = [X] factors.map: { 0 .. .value }
    +factors.keys == 1
    ?? $sort
      ?? flat sort (these «**« upto).grep: * !== N
      !! flat (these «**« upto).grep: * !== N
    !! $sort
      ?? flat sort ([×] .list for these «**« upto).grep: * !== N
      !! flat ([×] .list for these «**« upto).grep: * !== N
}

multi proper-divisors (Int \N where SMALL, :s(:$sort) = False) is export {
    return (1,) if N.is-prime;
    my \sqrrt = (sqrt N).narrow;
    my \lower = (2 ..^ sqrrt.ceiling).grep: N %% *;
    $sort
      ?? flat 1, (sort flat lower, (Slip(sqrrt) if sqrrt ~~ Int), N «div« lower)
      !! flat 1, lower, (Slip(sqrrt) if sqrrt ~~ Int), N «div« lower
}

multi proper-divisors (Int \N where * < 1, :s(:$sort) = False) is export { () }

multi proper-divisors (Str $n, :s(:$sort) = False) is export {
    if $n.Numeric !~~ Failure {
        samewith (+$n).narrow, :sort($sort);
    } else {
        fail "proper-divisors() not defined for non Integer strings."
    }
}

multi proper-divisors (Any $n, :s(:$sort) = False) is export {
    fail "proper-divisors() not defined for {$n.^name} parameters. Coerce to Int before calling.";
}


=begin pod
=head1 NAME
Prime::Factor

[![Build Status](https://travis-ci.org/thundergnat/Prime-Factor.svg?branch=master)](https://travis-ci.org/thundergnat/Prime-Factor)

Find factors of a positive integer.

Exports the sub ```prime-factors()```
and a few other utility subs: ```divisors()``` and ```proper-divisors()```

=head1 SYNOPSIS


    use Prime::Factor;

    say prime-factors(720); # (2 2 2 2 3 3 5)

    say prime-factors('720'); # (2 2 2 2 3 3 5)

    say prime-factors(2**50-1) # (3 11 31 251 601 1801 4051)

    say prime-factors(-6); # ()

    say prime-factors(18.75); # Failure: message('prime-factors() not defined for non Integer parameters.')


    # divisors subs are unsorted by default, semi-random order

    put divisors 2**50-1;
    #`[1 251 601 150851 11 2761 6611 1659361 1801 452051 1082401 271682651 19811
     4972561 11906411 2988509161 4051 1016801 2434651 611097401 44561 11184811
     26781161 6722071411 7295851 1831258601 4384806451 1100586419201 80254361
     20143844611 48232870961 12106450611211 3 753 1803 452553 33 8283 19833
     4978083 5403 1356153 3247203 815047953 59433 14917683 35719233 8965527483
     12153 3050403 7303953 1833292203 133683 33554433 80343483 20166214233
     21887553 5493775803 13154419353 3301759257603 240763083 60431533833
     144698612883 36319351833633 31 7781 18631 4676381 341 85591 204941 51440191
     55831 14013581 33554431 8422162181 614141 154149391 369098741 92643783991
     125581 31520831 75474181 18944019431 1381391 346729141 830215991
     208384213741 226171381 56769016631 135928999981 34118178995231 2487885191
     624459182941 1495218999791 375299968947541 93 23343 55893 14029143 1023
     256773 614823 154320573 167493 42040743 100663293 25266486543 1842423
     462448173 1107296223 277931351973 376743 94562493 226422543 56832058293
     4144173 1040187423 2490647973 625152641223 678514143 170307049893
     407786999943 102354536985693 7463655573 1873377548823 4485656999373
     1125899906842623]


    # if you want sorted output, pass in a :sort or :s flag.

    put divisors 2**50-1, :sort;
    #`[1 3 11 31 33 93 251 341 601 753 1023 1801 1803 2761 4051 5403 6611 7781
     8283 12153 18631 19811 19833 23343 44561 55831 55893 59433 85591 125581
     133683 150851 167493 204941 256773 376743 452051 452553 614141 614823
     1016801 1082401 1356153 1381391 1659361 1842423 2434651 3050403 3247203
     4144173 4676381 4972561 4978083 7295851 7303953 11184811 11906411 14013581
     14029143 14917683 21887553 26781161 31520831 33554431 33554433 35719233
     42040743 51440191 75474181 80254361 80343483 94562493 100663293 154149391
     154320573 226171381 226422543 240763083 271682651 346729141 369098741
     462448173 611097401 678514143 815047953 830215991 1040187423 1107296223
     1831258601 1833292203 2487885191 2490647973 2988509161 4384806451
     5493775803 6722071411 7463655573 8422162181 8965527483 13154419353
     18944019431 20143844611 20166214233 25266486543 48232870961 56769016631
     56832058293 60431533833 92643783991 135928999981 144698612883 170307049893
     208384213741 277931351973 407786999943 624459182941 625152641223
     1100586419201 1495218999791 1873377548823 3301759257603 4485656999373
     12106450611211 34118178995231 36319351833633 102354536985693
     375299968947541 1125899906842623]

    # Proper divisors are nearly the same but don't return the number itself

    put proper-divisors 2**50-1;

    # or sorted

    put proper-divisors 2**50-1, :s;


=head1 USAGE


C<prime-factors()> - Returns the list of all of the prime factors of a positive
integer. Results are returned in sorted order smallest to largest. Will attempt
to coerce Integer numeric strings to an Integer and act on that. Returns an
empty list for Integers < 2. Returns a Failure for non Integer parameters.

C<divisors()> - Returns the list of all the whole number divisors of a positive
integer, including 1 and itself. Results are not guaranteed to be in any order.
If you want ordered results, pass in the C<:sort> or C<:s> flag set to a truthy
value. Will attempt to coerce Integer numeric strings to an Integer and act on
that. Returns an empty list for Integers < 1. Returns a Failure for non Integer
parameters.

C<proper-divisors()> - Returns the list of all the whole number divisors of a
positive integer > 1, including 1 but not itself. Results are not guaranteed to
be in any order. If you want ordered results, pass in the C<:sort> or C<:s> flag
set to a truthy value. By definition, 1 has no proper divisors. Will attempt to
coerce Integer numeric strings to an Integer and act on that. Returns an empty
list for Integers < 2. Returns a Failure for non Integer parameters.

=head1 BUGS

Not very fast for very large integers. Or more accurately: not very fast for
integers that have two or more prime factors larger than ~2^40.

This would probably be better as a CORE function but until and if that arrives,
this is available.

=head1 AUTHOR

Stephen Schulze (often seen lurking on #perl6 IRC as thundergnat)

C<prime-factor()> adapted from code from Damian Conways "On the Shoulders of Giants"
presentation at YAPC::NA 2016 and Wikipedia "Pollard's rho algorithm".

C<divisors()> and C<proper-divisors()> adapted from code from Damian Conway blog
post: L<"With friends like these"|http://blogs.perl.org/users/damian_conway/2019/08/with-friends-like-these.html>.

=head1 LICENSE

Licensed under The Artistic 2.0; see LICENSE.

=end pod
