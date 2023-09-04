unit module Numbers:ver<2.8.2>:auth<github:thundergnat>;

# Arrays probably should be constants but constant arrays and pre-comp
# don't get along very well right now.
my @I = <zero one    two    three    four     five    six     seven     eight    nine
         ten  eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen>;
my @X = <0    X      twenty thirty   forty    fifty   sixty   seventy   eighty   ninety>;
my @C = @I »~» ' hundred';
my @M = (<0 thousand>,
    ((<m b tr quadr quint sext sept oct non>,
    (map { ('', <un duo tre quattuor quin sex septen octo novem>).flat X~ $_ },
    <dec vigint trigint quadragint quinquagint sexagint septuagint octogint nonagint>),
    'cent').flat X~ 'illion')).flat;

my @d = < zeroth first    second    third      fourth     fifth     sixth     seventh     eighth     ninth
          tenth  eleventh twelfth   thirteenth fourteenth fifteenth sixteenth seventeenth eighteenth nineteenth >;
my @t = < ''     ''       twentieth thirtieth  fortieth   fiftieth  sixtieth  seventieth  eightieth  ninetieth >;

my $COMMA = ', ';

sub no-commas ($flag = True) is export { $COMMA = $flag ?? ' ' !! ', ' }

sub term:<no-commas?> is export { $COMMA eq  ', ' ?? False !! True  }

multi sub cardinal ($rat is copy, :sep(:$separator) = ' ', :den(:$denominator), :im(:$improper) ) is export {
    if $rat.substr(0,1) eq '-' {
        return "negative {cardinal($rat.substr(1).Rat, :separator($separator), :denominator($denominator), :improper($improper)) }"
    }
    $rat .= Numeric.Rat;
    return cardinal($rat.narrow) if $rat.narrow ~~ Int;
    my ($num, $denom) = $rat.nude;
    if $denominator { # handle common denominator setup
        $num = ($rat * $denominator).round;
        $denom = $denominator;
    }
    my $s; # String to accumulate cardinal

    unless $improper {
        # handle improper fractions
        my $whole = $num div $denom;
        $num %= $denom;
        # add whole number
        $s ~= cardinal($whole) if $whole;
        # return if there are no fractional portions
        return $s // 'zero' unless $num;
        # add 'and' separator between whole and fractional
        $s ~= ' and ' if $whole;
    }

    # numerator is just a regular cardinal, add a separator if desired
    $s ~= cardinal($num) ~ $separator;
    # now determine the denominator
    if $denom == 2 { # special case irregular halfs
        if $num == 1 {
            $s ~= 'half';
        } else {
            $s ~= 'halves'
        }
        return $s;
    } elsif $denom == 4 { # special case irregular fourths
        $s ~= 'quarter';
        $s ~= 's' if $num != 1;
        return $s;
    } else { # special case even 'one' magnitude denominators
        my $cen = $denom.chars > 3 ?? $denom.substr(*-3) !! $denom;
        my $mil = $denom - $cen;
        if ($mil.chars == 3 || ($mil.chars - 1) %% 3) && (not +$cen)
         && (+$mil.substr(0,1) == 1) && (+$mil.substr(1) == 0) {
            # Drop the one for one thousandth, one millionth, etc
            $s ~= cardinal($mil).substr(4);
        } else {
            $s ~= cardinal($mil) if $mil;
        }
        if +$cen { # most of the special casing takes place in the last 3 digits
            $s ~= ' ' if $mil;
            if $cen %% 100 {
                if $cen == 100 and not $mil {
                    # Drop the one for even one hundredth
                    $s ~= 'hundredth'
                } else {
                    $s ~= cardinal($cen) ~ 'th'
                }
            } elsif $cen > 100 {    # irregulars galore
                my $hun = $cen.substr(0,1) * 100;
                $cen -= $hun;
                $s ~= cardinal($hun) ~ ' ';
                if $cen %% 10 {
                    $s ~=  @t[$cen / 10]
                } else {
                    if $cen > 19 {
                        my $ten = $cen.substr(0,1) * 10;
                        $s ~= cardinal($ten) ~ '-' if +$ten;
                        $s ~=  @d[$cen.substr(*-1)];
                    } else {
                        $s ~=  @d[$cen];
                    }
                }
            } elsif $cen && $cen < 20 {
                $s ~=  @d[$cen];
            } else {
                if $cen %% 10 {
                    $s ~=  @t[$cen / 10]
                } else {
                    $s ~= cardinal((+$cen).substr(0,1) * 10)
                    ~ '-' ~ @d[$cen.substr(*-1)];
                }
            }
        } else { # add suffix for denominator with 000 for last three digits
            $s ~= 'th';
        }
        # correct for pluralization
        $s ~= 's' if $num != 1;
        $s;
    }
}

multi sub cardinal (Int $int, *%) is export {
    if $int.substr(0,1) eq '-' { return "negative {cardinal($int.substr(1))}" }
    if $int == 0 { return @I[0] } # Bools dispatch as Ints.
    if $int == 1 { return @I[1] } # Handle them directly
    my $m = 0;
    return join $COMMA, reverse gather for $int.flip.comb(/\d ** 1..3/) {
        my ( $i, $x, $c ) = .comb».Int;
        if $i or $x or $c {
            take join ' ', gather {
                if $c { take @C[$c] }
                if $x and $x == 1 { take @I[$i+10] }
                else {
                    if $x and $i {
                        take join '-', @X[$x], @I[$i];
                    } else {
                        if $x { take @X[$x] }
                        if $i { take @I[$i] }
                    }
                }
                take @M[$m] // fail "WOW! ZILLIONS!\n" if $m;
            }
        }
        $m++;
    }
}

multi sub cardinal (Num $num, *%) is export {
    if $num < 0 { return "negative {cardinal(-$num)}" }
    die if $num ~~ Inf or $num ~~ NaN;
    my ($mantissa, $exponent) = $num.fmt("%.14e").split('e')».Numeric;
    my ($whole, $fraction) = $mantissa.split('.');
    $whole.=Numeric;
    $fraction //= '';
    $fraction.=subst( / 0*$ /, '' );
    my $f = +$fraction ?? join( ' ', ' point', @I[$fraction.comb]) !! '';
    $exponent ??
      "{@I[$whole.comb]}$f times ten to the { $exponent.&ordinal }" !!
      "{@I[$whole.comb]}$f";
}

sub cardinal-year ($year where 0 < $year < 10000, :$oh = 'oh-' ) is export {
    if $year %% 1000 {
        return cardinal($year.substr(0,1)) ~ ' thousand';
    } elsif $year %% 100  {
        my ($, $cen) = $year.flip.comb(/\d ** 1..2/);
        return cardinal($cen.flip) ~ ' hundred';
    }
    my ($l, $h) = $year.flip.comb(/\d ** 1..2/).».flip;
    if $h and $l < 10 {
        return cardinal($h) ~ ' ' ~ $oh ~ cardinal($l);
    } elsif $l < 10 {
        return cardinal($l);
    }
    return join ' ', cardinal($h), cardinal($l);
}

sub ordinal ($int is copy) is export {
    $int .= Int;
    if $int < 0 { return "negative {ordinal($int.abs)}" }
    my $ten = $int.chars > 2 ?? +$int.substr(*-2) !! +$int;
    my $mil = $int - $ten;
    my $s = '';
    if $mil > 0 {
        $s = cardinal($mil);
    }
    if +$mil and !+$ten { return $s ~ 'th' }
    if +$mil and  +$ten { $s ~= ' ' }
    if $ten < 20 {
        $s ~= @d[$ten]
    } elsif +$ten and $ten %% 10 {
        $s ~= @t[$ten div 10]
    } else {
        $s ~= cardinal($ten div 10 * 10) ~ '-' ~ @d[$ten % 10]
    }
    $s;
}

sub ordinal-digit ($int is copy, :$u = False, :$c = False) is export {
    my %s = $u
      ?? (:nd<ⁿᵈ>, :st<ˢᵗ>, :rd<ʳᵈ>, :th<ᵗʰ>)
      !! (:nd<nd>, :st<st>, :rd<rd>, :th<th>);
    $int .= Int;
    my $ten = $int.abs.chars > 2 ?? +$int.substr(*-2) !! +$int.abs;
    my $s = $int;
    $s = comma $int if $c;

    if 10 < $ten < 14  {
        $s ~= %s<th>;
    } else {
        given $int.substr(*-1) {
            when 1  { $s ~= %s<st> }
            when 2  { $s ~= %s<nd> }
            when 3  { $s ~= %s<rd> }
            default { $s ~= %s<th> }
        }
    }
    $s;
}

sub comma ($i where * ~~ Int|Rat|Str) is export {
    fail "$i doesn't look like an Integer or Rational." unless +$i ~~ Numeric;
    my $s = $i < 0 ?? '-' !! '';
    my ($whole, $frac) = $i.split('.');
    $frac = $frac.defined ?? ".$frac" !! '';
    $s ~ $whole.abs.flip.comb(3).join(',').flip ~ $frac
}

sub pretty-rat (Real $number) is export {
    return $number unless $number ~~ Rat|FatRat;
    return $number.numerator if $number.denominator == 1;
    $number.nude.join: '/';
}

sub super ($i) is export { $i.trans(['+','-','0','1','2','3','4','5','6','7','8','9','(',')','e','i'] => ['⁺','⁻','⁰','¹','²','³','⁴','⁵','⁶','⁷','⁸','⁹','⁽','⁾','ᵉ','ⁱ']) }

# Aliases
our &prat   is export(:short) = &pretty-rat;
our &ord-n  is export(:short) = &ordinal;
our &ord-d  is export(:short) = &ordinal-digit;
our &card   is export(:short) = &cardinal;
our &card-y is export(:short) = &cardinal-year;


=begin pod
=head1 NAME
Lingua::EN::Numbers

[![test](https://github.com/thundergnat/Lingua-EN-Numbers/actions/workflows/test.yml/badge.svg)](https://github.com/thundergnat/Lingua-EN-Numbers/actions/workflows/test.yml)

Various number-string conversion utility routines.

Convert numbers to their cardinal or ordinal representation.

Several other numeric string "prettifying" routines.


=head1 SYNOPSIS


    use Lingua::EN::Numbers;

    # Integers
    say cardinal(42);             # forty-two
    say cardinal('144');          # one hundred forty-four
    say cardinal(76541);          # seventy-six thousand, five hundred forty-one

    # Rationals
    say cardinal(7/2);            # three and one half
    say cardinal(7/2, :improper); # seven halves
    say cardinal(7/2, :im );      # seven halves
    say cardinal(15/4)            # three and three quarters
    say cardinal(3.75)            # three and three quarters
    say cardinal(15/4, :improper) # fifteen quarters
    say cardinal('3/16');         # three sixteenths

    # Years
    say cardinal-year(1800)       # eighteen hundred
    say cardinal-year(1905)       # nineteen oh-five
    say cardinal-year(2000)       # two thousand
    say cardinal-year(2015)       # twenty fifteen

    # cardinal vs. cardinal-year
    say cardinal(1776);           # one thousand, seven hundred seventy-six
    say cardinal-year(1776)       # seventeen seventy-six


    # Sometimes larger denominators make it difficult to discern where the
    # numerator ends and the denominator begins. Change the separator to
    # make it easier to tell.

    say cardinal(97873/10000000);
    # ninety seven thousand, eight hundred seventy-three ten millionths

    say cardinal(97873/10000000, :separator(' / '));
    # ninety seven thousand, eight hundred seventy-three / ten millionths


    # If you want to use a certain denominator in the display and not reduce
    # fractions, specify a common denominator.

    say cardinal(15/1000);                      # three two hundredths
    say cardinal(15/1000, :denominator(1000));  # fifteen thousandths
    # or
    say cardinal(15/1000, denominator => 1000); # fifteen thousandths
    # or
    say cardinal(15/1000, :den(1000) );         # fifteen thousandths

    # Ordinals
    say ordinal(1);               # first
    say ordinal(2);               # second
    say ordinal(123);             # one hundred twenty-third

    # Ordinal digit
    say ordinal-digit(22);        # 22nd
    say ordinal-digit(1776);      # 1776th
    say ordinal-digit(331 :u);    # 331ˢᵗ
    say ordinal-digit(12343 :c);  # 12,343rd

    # Use pretty-rat() to print rational strings as fractions rather than
    # as decimal numbers. Whole number fractions will be reduced to Ints.
    say pretty-rat(1.375); # 11/8
    say pretty-rat(8/2);   # 4

    # no-commas flag

    # save state
    my $state = no-commas?;

    # disable commas
    no-commas;

    say cardinal(97873/10000000);
    # ninety seven thousand eight hundred seventy-three ten millionths

    # restore state
    no-commas($state);


    # Commas routine
    say comma( 5.0e9.Int );       # 5,000,000,000
    say comma( -123456 );         # -123,456
    say comma(  7832.00 );        # 7,832
    say comma( '7832.00' );       # 7,832.00

    # Super routine
    say super('32');              # ³²
    say super -47;                # ⁻⁴⁷


Or, import the short form routine names:

    use Lingua::EN::Numbers :short;

    say card(42);    # forty-two
    say card-y(2020) # twenty twenty
    say ord-n(42);   # forty-second
    say ord-d(42);   # 42nd
    say card(.875)   # seven eights
    say prat(.875);  # 7/8



=head1 DESCRIPTION

Exports the Subs:

=item L<cardinal( )|#cardinal> - short: card()
=item L<cardinal-year( )|#cardinal-year> - short: card-y()
=item L<ordinal( )|#ordinal> - short: ord-n()
=item L<ordinal-digit( )|#ordinal-digit> - short: ord-d()
=item L<comma( )|#comma>
=item L<pretty-rat( )|#pretty-rat> - short: prat()
=item L<super( )|#super>

and Flag:
=item L<no-commas|#no-commas>

Short form routine names are only available if you specifically import them:

C<use Lingua::EN::Numbers :short;>

=head2 <a name="cardinal"></a>cardinal( ) - short: card()

Returns cardinal representations of integers following the American English,
short scale convention.

See: https://en.wikipedia.org/wiki/Long_and_short_scales


=head3 cardinal( $number, :separator($str), :denominator($val), :improper );

=item1 $number
=item2 value; required, any Real number (Rat, Int, or Num)

=item1 :separator or :sep
=item2 value; optional, separator between numerator and denominator, defaults to space. Ignored if a non Rat is passed in.

=item1 :denominator or :den
=item2 value; optional, integer denominator to use for representation, do not reduce to lowest terms. Ignored if a non Rat is passed in.

=item1 :improper or :im
=item2 flag; optional, do not regularize improper fractions. Ignored if a non Rat is passed in.

Pass C<cardinal()> a number or something that can be converted to one; returns its
cardinal representation.

Recognizes integer numbers from:
-9999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999
9999999999999999999999999999999999999999999999999999999999999999999999999999
to
99999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999
99999999999999999999999999999999999999999999999999999999999999999999999999999
999999999999999999999999999999999999999999999999999999999999999999999999999

Thats 306 9s, negative, through positive:

nine hundred ninety-nine centillion, nine hundred ninety-nine
novemnonagintillion, nine hundred ninety-nine octononagintillion, nine hundred
ninety-nine septennonagintillion, nine hundred ninety-nine sexnonagintillion,
nine hundred ninety-nine quinnonagintillion, nine hundred ninety-nine
quattuornonagintillion, nine hundred ninety-nine trenonagintillion, nine hundred
ninety-nine duononagintillion, nine hundred ninety-nine unnonagintillion, nine
hundred ninety-nine nonagintillion, nine hundred ninety-nine
novemoctogintillion, nine hundred ninety-nine octooctogintillion, nine hundred
ninety-nine septenoctogintillion, nine hundred ninety-nine sexoctogintillion,
nine hundred ninety-nine quinoctogintillion, nine hundred ninety-nine
quattuoroctogintillion, nine hundred ninety-nine treoctogintillion, nine hundred
ninety-nine duooctogintillion, nine hundred ninety-nine unoctogintillion, nine
hundred ninety-nine octogintillion, nine hundred ninety-nine
novemseptuagintillion, nine hundred ninety-nine octoseptuagintillion, nine
hundred ninety-nine septenseptuagintillion, nine hundred ninety-nine
sexseptuagintillion, nine hundred ninety-nine quinseptuagintillion, nine hundred
ninety-nine quattuorseptuagintillion, nine hundred ninety-nine
treseptuagintillion, nine hundred ninety-nine duoseptuagintillion, nine hundred
ninety-nine unseptuagintillion, nine hundred ninety-nine septuagintillion, nine
hundred ninety-nine novemsexagintillion, nine hundred ninety-nine
octosexagintillion, nine hundred ninety-nine septensexagintillion, nine hundred
ninety-nine sexsexagintillion, nine hundred ninety-nine quinsexagintillion, nine
hundred ninety-nine quattuorsexagintillion, nine hundred ninety-nine
tresexagintillion, nine hundred ninety-nine duosexagintillion, nine hundred
ninety-nine unsexagintillion, nine hundred ninety-nine sexagintillion, nine
hundred ninety-nine novemquinquagintillion, nine hundred ninety-nine
octoquinquagintillion, nine hundred ninety-nine septenquinquagintillion, nine
hundred ninety-nine sexquinquagintillion, nine hundred ninety-nine
quinquinquagintillion, nine hundred ninety-nine quattuorquinquagintillion, nine
hundred ninety-nine trequinquagintillion, nine hundred ninety-nine
duoquinquagintillion, nine hundred ninety-nine unquinquagintillion, nine hundred
ninety-nine quinquagintillion, nine hundred ninety-nine novemquadragintillion,
nine hundred ninety-nine octoquadragintillion, nine hundred ninety-nine
septenquadragintillion, nine hundred ninety-nine sexquadragintillion, nine
hundred ninety-nine quinquadragintillion, nine hundred ninety-nine
quattuorquadragintillion, nine hundred ninety-nine trequadragintillion, nine
hundred ninety-nine duoquadragintillion, nine hundred ninety-nine
unquadragintillion, nine hundred ninety-nine quadragintillion, nine hundred
ninety-nine novemtrigintillion, nine hundred ninety-nine octotrigintillion, nine
hundred ninety-nine septentrigintillion, nine hundred ninety-nine
sextrigintillion, nine hundred ninety-nine quintrigintillion, nine hundred
ninety-nine quattuortrigintillion, nine hundred ninety-nine tretrigintillion,
nine hundred ninety-nine duotrigintillion, nine hundred ninety-nine
untrigintillion, nine hundred ninety-nine trigintillion, nine hundred
ninety-nine novemvigintillion, nine hundred ninety-nine octovigintillion, nine
hundred ninety-nine septenvigintillion, nine hundred ninety-nine
sexvigintillion, nine hundred ninety-nine quinvigintillion, nine hundred
ninety-nine quattuorvigintillion, nine hundred ninety-nine trevigintillion, nine
hundred ninety-nine duovigintillion, nine hundred ninety-nine unvigintillion,
nine hundred ninety-nine vigintillion, nine hundred ninety-nine novemdecillion,
nine hundred ninety-nine octodecillion, nine hundred ninety-nine
septendecillion, nine hundred ninety-nine sexdecillion, nine hundred ninety-nine
quindecillion, nine hundred ninety-nine quattuordecillion, nine hundred
ninety-nine tredecillion, nine hundred ninety-nine duodecillion, nine hundred
ninety-nine undecillion, nine hundred ninety-nine decillion, nine hundred
ninety-nine nonillion, nine hundred ninety-nine octillion, nine hundred
ninety-nine septillion, nine hundred ninety-nine sextillion, nine hundred
ninety-nine quintillion, nine hundred ninety-nine quadrillion, nine hundred
ninety-nine trillion, nine hundred ninety-nine billion, nine hundred ninety-nine
million, nine hundred ninety-nine thousand, nine hundred ninety-nine

Handles Rats limited to the integer limits for the numerator and denominator.

When converting rational numbers, the word "and" is inserted between any whole
number portion and the fractional portions of the number. If you have an "and"
in the output, the input number had a fractional portion.

By default, C<cardinal()> reduces fractions to their lowest terms. If you want to
specify the denominator used to display, pass in an integer to the :denominator
option.

It is probably best to specify a denominator that is a common divisor for
the denominator. C<cardinal()> will work with any integer denominator, and will
scale the numerator to match, but will round off the numerator to the nearest
integer after scaling, so some error will creep in if denominator is NOT a
common divisor with the denominator.


Recognizes Nums up to about 1.79e308. (2¹⁰²⁴ - 1)

When converting Nums, reads out the enumerated digits for the mantissa and
returns the ordinal exponent.

E.G. C<cardinal(2.712e7)> will return:

    two point seven one two times ten to the seventh

If you want it to be treated like an integer or rational, coerce it to the
appropriate type.

C<cardinal(2.712e7.Int)> to get:

    twenty-seven million, one hundred twenty thousand

C<cardinal(1.25e-3)> returns:

    one point two five times ten to the negative third

C<cardinal(1.25e-3.Rat)> returns:

    one eight hundredth


=head2 <a name="cardinal-year"></a>cardinal-year( ) - short: card-y()

Converts integers from 1 to 9999 to the common American English convention.

=head3 cardinal-year( $year, :oh($str) );

=item1 $year
=item2 value; must be an integer between 1 and 9999 or something that can be coerced to an integer between 1 and 9999.


=item1 :oh
=item2 value; optional, string to use for the "0" years after a millennium. Default 'oh-'. Change to ' ought-' or some other string if desired.


Follows the common American English convention for years:

    2015 -> twenty fifteen.

    1984 -> nineteen eighty-four.

Even millenniums are returned as thousands:

    2000 -> two thousand.

Even centuries are returned as hundreds:

    1900 -> nineteen hundred.

Years 1 .. 9 in each century are returned as ohs:

    2001 -> twenty oh-one.

Configurable with the :oh parameter. Default is 'oh-'. Change to
'ought-' if you prefer twenty ought-one, or something else if that is your
preference.

=head2 <a name="ordinal"></a>ordinal( ) - short: ord-n()

Takes an integer or something that can be coerced to an integer and returns a
string similar to the cardinal() routine except it is positional rather than
valuation.

E.G. 'first' rather than 'one', 'eleventh' rather than 'eleven'.

=head3 ordinal( $integer )

=item1 $integer
=item2 value; an integer or something that can be coerced to a sensible integer value.

=head2 <a name="ordinal-digit"></a>ordinal-digit( ) - short: ord-d()

Takes an integer or something that can be coerced to an integer and returns the
given numeric value with the appropriate suffix appended to the number. 1 ->
1st, 3 -> 3rd, 24 -> 24th etc.

=head3 ordinal-digit( $integer, :u, :c )

=item1 $integer
=item2 value; an integer or something that can be coerced to a sensible integer value.

=item1 :u
=item2 boolean; enable Unicode superscript ordinal suffixes (ˢᵗ, ⁿᵈ, ʳᵈ, ᵗʰ). Default false.

=item1 :c
=item2 boolean; add commas to the ordinal number. Default false.

=head2 <a name="comma"></a>comma( )

Insert commas into a numeric string following the English convention. Groups of
3-orders-of-magnitude for whole numbers, fractional portions are unaffected.

=head3 comma( $number )

=item1 $number
=item2 value; an integer, rational, int-string, rat-string or numeric string.


Will accept an Integer, Int-String, Rational, Rat-String or a numeric string
that looks like an Integer or Rational. Any non-significant leading zeros are
dropped. Non-significant trailing zeros are dropped for numeric rationals. If
you want to retain non-significant trailing zeros in Rats, pass the argument as a
string.

=head2 <a name="pretty-rat"></a> pretty-rat() - short: prat()

A "prettifying" routine to render rational numbers as a fraction. Rats that have
a denominator of 1 will be rendered as integers.

=head3 pretty-rat($number)

=item1 $number
=item2 value; Any real number. Integers and Nums will be passed along unchanged; Rats will be converted to a fractional representation.

=head2 <a name="no-commas"></a>no-commas

A global flag for the C<cardinal()> and C<ordinal()> routines that disables / enables
returning commas between 3-order-of-magnitude groups.

=head2 <a name="pretty-rat"></a> pretty-rat() - short: prat()

A "prettifying" routine to render rational numbers as a fraction. Rats that have
a denominator of 1 will be rendered as integers.

=head2 <a name="super"></a> super()

A "prettifying" routine to render numbers as Unicode superscripts. Mostly for
formatting output strings. Not convieniently usable for a variable exponent.

=head3 super($number)

=item1 $number
=item2 value; Any real integer or integer string.

Note that a numeric of -0 will be superscripted to ⁰ since Raku treats numeric
-0 and 0 as equivalent. If it is important to have the negative sign show up,
pass the value as a string "-0".  Provides superscript versions of:
+-0123456789()ei . Technically, super will work with any numeric, but Unicode
does not offer a superscript decimal point, so it is of limited use for
rationals and scientific notation.

=head2 <a name="no-commas"></a>no-commas

A global flag for the C<cardinal()> and C<ordinal()> routines that disables / enables
returning commas between 3-order-of-magnitude groups.

=head3 no-commas( $bool )

=item1 $bool
=item2 A truthy / falsey value to enable / disable inserting commas into spelled out numeric strings.

Takes a Boolean or any value that can be coerced to a Boolean as a flag to
disable / enable inserting commas. Absence of a value is treated as True. E.G.

    no-commas;

is the same as

    no-commas(True);

to re-enable inserting commas:

    no-commas(False);

Disabled (False) by default. May be enabled and disabled as desired, even within
a single block; the flag is global though, not lexical. If you disable commas
deep within a block, it will affect all C<ordinal()> and C<cardinal()> calls
afterwords, even in a different scope. If your script is part of a larger
application, you may want to query the C<no-commas> state and restore it after any
modification.

Query the no-commas flag state with:

    my $state = no-commas?;

Returns the current flag state as a Boolean: True - commas disabled, False -
commas enabled. Does not modify the current state.

Restore it with:

    no-commas($state);

NOTE: the C<comma()> routine and C<no-commas> flag have nothing to do with each other,
do not interact, and serve completely different purposes.

----

=head1 BUGS

Doesn't handle complex numbers. Does some cursory error trapping and
coercion but the foot cannon is still loaded.


=head1 AUTHOR

Original Integer cardinal code by TimToady (Larry Wall).

See: http://rosettacode.org/wiki/Number_names#Raku

Other code by thundergnat (Steve Schulze).

=head1 LICENSE

Licensed under The Artistic 2.0; see LICENSE.
=end pod
