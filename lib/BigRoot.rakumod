unit class BigRoot:ver<0.1.0>:auth<github:juliodcs>;

# Subset definitions
my subset PositiveNumber where { $_ >= 0 and $_ < ∞ };
my subset RootNumber of PositiveNumber where { $_ ~~ Int or $_ ~~ Rational };
my subset Natural of UInt where { $_ > 0 and $_ < ∞ };

# Enable/Disable result cache
method use-cache is rw {
    state Bool $use-cache = True
}

# To put precision into scale:
#   * NASA uses 15 decimals for Pi:
#     See: https://www.jpl.nasa.gov/edu/news/2016/3/16/how-many-decimals-of-pi-do-we-really-need/
#   * 1/10^30: a millimeter compared to the diameter of the universe
#   * 1/10^35: diameter of a human hair compared to the diameter of the universe
#   * 1/10^42: size of a proton compared to the diameter of the universe
#   * 1/10^62: Planck length compared to the diameter of the universe
#   * 1/10^86: one atom out of all atoms of the universe
method precision is rw {
    state Natural $precision = 30;
}

method !result(PositiveNumber:D $number, RootNumber:D $root) is rw {
    state %results = Hash<RootNumber, FatRat, Natural>.new;
    %results{$root}{$number.FatRat}{self.precision}
}

# Calculate Newton's root and store the result on cache (if cache is enabled)
method newton's-root(RootNumber:D :$root, PositiveNumber:D :$number) returns FatRat {
    unless self.use-cache {
        return self!calculate-root: $root, $number;
    }

    without self!result($number, $root) {
        self!result($number, $root) = self!calculate-root: $root, $number;
    }

    return self!result: $number, $root;
}

method newton's-sqrt(PositiveNumber:D $number) {
    return self.newton's-root: root => 2, :$number;
}

# Calculates a root via Newton's method.
# If the root is a rational number, the exponentiation is done first:
# For example: 0.4-root(20) ==> (2/5)-root(20) ==> 2-root(20**5)
method !calculate-root(RootNumber:D $root, PositiveNumber:D $number) returns FatRat:D {
    my (Int $numerator, Int $denominator) = $root.FatRat.nude;
    return self!calculate-uint-root: $numerator, $number.FatRat ** $denominator;
}

# Calculate Newton's root for an UInt-based root
method !calculate-uint-root(UInt:D $root, PositiveNumber:D $number) returns FatRat:D {
    # Our error margin is required precision + 1, so We can safely round it
    my FatRat $error = FatRat.new: 1, 10 ** (self.precision + 1);

    # convert number to FatRat since we will later check numerator/denominator values
    my FatRat $input = $number.FatRat;

    # We use Raku's native math operations to get the first guess
    my FatRat $guess = ($input ** FatRat.new(1, $root)).FatRat;

    my FatRat $diff = $input;

    while $diff > $error {
        # If we have more decimal numbers than required, we optimize FatRat
        $guess = $guess.numerator.chars > self.precision
                # Optimize FatRat
                ?? $guess.round: FatRat.new: 1, 10 ** (self.precision + 1)
                # Do not optimize, rounding takes some time so we would get diminishing returns
                !! $guess;

        # Newton's new guess:
        my FatRat $new-guess = (($root - 1) * $guess + $input / ($guess ** ($root - 1))) / $root;

        # diff from previous guess will allow us to check required precision
        $diff = abs($new-guess - $guess);

        # Store guess
        $guess = $new-guess;
    }

    # return rounded result for required precision
    return $guess.round: FatRat.new: 1, 10 ** self.precision;
}

=begin pod

=head1 NAME

BigRoot - Class for supporting roots with arbitrary precision.

=head1 SYNOPSIS

    use BigRoot;

    # Can change precision level (Default precision is 30)
    BigRoot.precision = 50;

    my $root2 = BigRoot.newton's-sqrt: 2;
    # 1.41421356237309504880168872420969807856967187537695

    say $root2.WHAT;
    # (FatRat)

    # Can use other root numbers
    say BigRoot.newton's-root: root => 3, number => 30;
    # 3.10723250595385886687766242752238636285490682906742

    # Numbers can be Int, Rational and Num:
    say BigRoot.newton's-sqrt: 2.123;
    # 1.45705181788431944566113502812562734420538186940001

    # Can use other rational roots
    say BigRoot.newton's-root: root => FatRat.new(2, 3), number => 30;
    # 164.31676725154983403709093484024064018582340849939498

    # Results are rounded:

    BigRoot.precision = 8;
    say BigRoot.newton's-sqrt: 2;
    # 1.41421356

    BigRoot.precision = 7;
    say BigRoot.newton's-sqrt: 2;
    # 1.4142136

    # By default, results are cached for given precision.
    BigRoot.precision = 150_000;
    BigRoot.newton's-sqrt: 2;
    my $start = now;
    BigRoot.newton's-sqrt: 2;
    say (now - $start) < 0.1;
    # (True)

    # Cache can be disabled with:
    BigRoot.use-cache = False;

=head1 DESCRIPTION

This module provides a way of having arbitrary precision for roots. In order to do that it calculates the roots using L<Newton's method|https://en.wikipedia.org/wiki/Newton%27s_method> and uses raku's C<FatRat> primitives.

The module supports rooting C<Int>, C<Num>, and C<Rational> numbers and allows using a Rational number as the root. Also, the level of precision can be changed.

=head1 METHODS

=head2 method precision

    method precision is rw

Allows for getting/setting the level of precision. Defaults to 30.

To put precision into scale:

=item L<NASA uses 15 decimals for Pi|https://www.jpl.nasa.gov/edu/news/2016/3/16/how-many-decimals-of-pi-do-we-really-need/>
=item 1/10^30: a millimeter compared to the diameter of the universe
=item 1/10^35: diameter of a human hair compared to the diameter of the universe
=item 1/10^42: size of a proton compared to the diameter of the universe
=item 1/10^62: Planck length compared to the diameter of the universe
=item 1/10^86: one atom out of all atoms of the universe

=head2 method newton's-root

    method newton's-root(RootNumber:D :$root, PositiveNumber:D :$number) returns FatRat

Calculates the nth-root for the given number

=head2 method newton's-sqrt

    method newton's-sqrt(PositiveNumber:D $number)

Calculates square root for the given number.

Same as C<<newton's-root(root => 2, :$number)>>

=head2 method use-cache

    method use-cache is rw

Allows enabling/disabling result cache (cache is enabled by default)

=end pod
