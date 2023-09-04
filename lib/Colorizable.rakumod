=begin pod
=head1 Colorizable

A Raku module for colorizing text using ANSI escape codes.

=head2 Synopsis

=begin code
use Colorizable;

my $string = "Hello" but Colorizable;

given $string {
    say .colorize: red;                            # red text
    say .colorize: :fg(red);                       # same as previous
    say .red;                                      # same as previous

    say .colorize: red, blue;                      # red text on blue background
    say .colorize: :fg(red), :bg(blue);            # same as previous
    say .red.on-blue;                              # same as previous

    say .colorize: red, blue, bold;                # bold red text on blue background
    say .colorize: :fg(red), :bg(blue), :mo(bold); # same as previous
    say .red.on-blue.bold;                         # same as previous
}
=end code

=head2 Installation

From L<Raku module ecosystem|https://modules.raku.org/> using C<zef>:

=begin code
$ zef install Colorizable
=end code

From source code:

=begin code
$ git clone https://gitlab.com/uzluisf/raku-colorizable.git
$ cd raku-colorizable/
$ zef install .
=end code

=head2 Description

The module allows to colorize text using ANSI escape code by
composing the C<Colorizable> role into a string. After doing this,
the method C<colorize> can be used to set the text color, background color
and text effects (e.g., bold, italic, etc.):

=begin code
use Colorizable;

my $planet = "Arrakis" but Colorizable;
say $planet.colorize(:fg(blue), :bg(red), :mo(bold));
=end code

If composed into a class, C<Colorizable> assumes the class implements
the appropriate C<Str> method:

=begin code
use Colorizable;

class A does Colorizable {
}

say A.new.colorize(blue); #=> A<94065101711120>, in blue

class B does Colorizable {
    method Str { 'Class B' }
}

say B.new.colorize(blue); #=> class B, in blue
=end code

Invocations to the C<colorize> method are chainable:

=begin code
use Colorizable;

my $text = "Bold red text on yellow background" but Colorizable;

say $text
.colorize(:fg(red))
.colorize(:bg(yellow))
.colorize(:mo(bold));
=end code

Colors and modes can be invoked as methods: C<.color> for foreground,
C<.on-color> for background, and C<.mode> for mode given C<color> and
C<mode> respectively:

=begin code
use Colorizable;

my $text = "Bold red text on yellow background" but Colorizable;

say $text.red.on-yellow.bold;
=end code

To get a list of available colors and modes, use the C<colors> and C<modes>
methods respectively

Although this might not be advisable, you can make regular strings colorizable
by augmenting the C<Str> class:

=begin code
use Colorizable;
use MONKEY-TYPING;

# making strings colorizable
augment class Str {
    also does Colorizable;
}

say "Bold red text on yellow background"
.colorize(:fg(red))
.colorize(:bg(yellow))
.colorize(:mo(bold));
=end code

Note the use of the pragma
L<C<MONKEY-TYPING>|https://docs.raku.org/language/pragmas#index-entry-MONKEY-TYPING__pragma>.

=head2 Methods
=end pod

# START OF CODE

enum Color is export (
    black   => 0, light-black   => 60,
    red     => 1, light-red     => 61,
    green   => 2, light-green   => 62,
    yellow  => 3, light-yellow  => 63,
    blue    => 4, light-blue    => 64,
    magenta => 5, light-magenta => 65,
    cyan    => 6, light-cyan    => 66,
    white   => 7, light-white   => 67,
    default-color => 9,
);

enum Mode is export (
    default-mode => 0, # Turn off all attributes
    bold         => 1, # Set bold mode
    italic       => 3, # Set italic mode
    underline    => 4, # Set underline mode
    blink        => 5, # Set blink mode
    swap         => 7, # Exchange foreground and background colors
    hide         => 8  # Hide text (foreground color would be the same as background)
);

role Colorizable:ver<0.1.1> is export {

    my subset AcceptedStrColor of Str where { Color.enums.contains($_) }
    my subset StrColor where {
        ($_ ~~ AcceptedStrColor|Color)
        || die "Value ({$_}) must be a valid color (string or enumeration). Call the colors method to get a list of available colors."
    }

    my subset AcceptedStrMode of Str where { Mode.enums.contains($_) }
    my subset StrMode where {
        ($_ ~~ AcceptedStrMode|Mode) ||
        || die "Value ({$_}) must be a valid mode (string or enumeration). Call the modes method to get a list of available modes."
    }

    submethod BUILD {
        self!color-methods;
        self!mode-methods;
    }

    #
    # Public methods
    #

    =begin colorize
    C«method colorize($fg, $bg, $mo)»

    Change color of string.

    B«Examples:»
    =begin code
    my $str = "Hello" does Colorizable;
    say $str.colorize(yellow);          # yellow text
    say $str.colorize('yellow');        # yellow text
    say $str.colorize(blue, red, bold); # bold blue text in red background
    =end code

    B«Parameters:»
    =item C«$fg» the string's foreground color
    =item C«$bg» the string's background color
    =item C«$mo» the string's mode
    =end colorize

    multi method colorize(
        StrColor $fg,
        StrColor $bg = Color,
        StrMode  $mo = Mode,
    ) {
        my %res = self!scan-string;
        self!set-values(%res, $fg, $bg, $mo);
        self!colorize-string(%res);
    }

    =begin colorize
    C«method colorize(:fg(:$foreground), :bg(:$background), :mo(:$mode))»

    Change color of string.

    B«Examples:»
    =begin code
    my $str = "Hello" does Colorizable;
    say $str.colorize(:fg(yellow));           # yellow text
    say $str.colorize(:foreground('yellow')); # yellow text
    say $str.colorize(:fg(blue), :bg(red));   # blue text in red background
    =end code

    B«Parameters:»
    =item C«$fg» the string's foreground color
    =item C«$bg» the string's background color
    =item C«$mo» the string's mode
    =end colorize

    multi method colorize(
        StrColor :fg(:$foreground) = Color,
        StrColor :bg(:$background) = Color,
        StrMode  :mo(:$mode)       = Mode,
    ) {
        my %res = self!scan-string;
        self!set-values(%res, $foreground, $background, $mode);
        self!colorize-string(%res);
    }

    =begin colors
    C«method colors(--> List)»

    Return list of available colors as allomorphs. By default,
    the C«IntSt» values for the foreground are returned. To return
    the values for the background, pass the Boolean named argument
    C«bg» (or C«background»).

    B«Examples:»
    =begin code
    my $str = "Hello" does Colorizable;
    say $str.colors.head(3).join(' ');           #=> «black red green␤»
    say $str.colors.head(3)».Int.join(' ');      #=> «30 31 32␤»
    say $str.colors(:bg).head(3).join(' ');      #=> «black red green␤»
    say $str.colors(:bg).head(3)».Int.join(' '); #=> «40 41 42␤»
    =end code
    =end colors

    method colors( Bool :bg(:$background) = False --> List ) {
        my $offset = $background.so ?? 40 !! 30;
        Color.enums.sort(*.value).map({
            IntStr.new($_.value + $offset, $_.key.Str)
        }).list
    }

    =begin modes
    C«method modes( --> List )»

    Return list of available modes as allomorphs.

    B«Examples:»
    =begin code
    my $str = "Hello" does Colorizable;
    say $str.modes.head(3).join(' ');      #=> «default-mode bold italic␤»
    say $str.modes.head(3)».Int.join(' '); #=> «0 1 3␤»
    =end code
    =end modes

    method modes( --> List ) {
        Mode.enums.sort(*.value).map({
            IntStr.new($_.value.Int, $_.key.Str)
        }).list
    }

    =begin is-colorized
    C«method is-colorized( --> Bool )»

    Return true if the string is colorized. Otherwise, false. A string
    is considered colorized if it has at least one element (foreground,
    background, or mode) set.

    B«Examples:»
    =begin code
    my $str = "Hello" does Colorizable;
    say $str.is-colorized;
    =end code
    =end is-colorized

    method is-colorized( ::?CLASS:D: --> Bool ) {
        self!scan-string<colors>.any.so
    }

    =begin uncolorize
    C«method uncolorize( --> Str )»

    Return uncolorized string.

    B«Examples:»
    =begin code
    my $str = "Hello" does Colorizable;
    say $str.uncolorize;
    =end code
    =end uncolorize

    method uncolorize( ::?CLASS:D: --> Str ) {
        self!scan-string<text>
    }

    =begin color-samples
    C«method color-samples()»

    Display color samples.

    B«Examples:»
    =begin code
    my $str = "Hello" does Colorizable;
    $str.color-samples; # display color samples
    =end code
    =end color-samples

    method color-samples( --> Nil ) {
        for self.modes.head(8) -> $mo {
            for self.colors.head(8) -> $fg {
                my $s = '';
                for self.colors(:bg).head(8) -> $bg {
                    my $format = ($mo, $fg, $bg)».Int.join(';');
                    $s ~= (" $format " but Colorizable).colorize(:$fg, :$bg, :$mo);
                }
                say $s;
            }
            say "";
        }
    }

    #
    # Private methods
    #

    # Return the colorized string. Note that Colorizable is composed into the
    # newly created string so as to allow for the chaining of the colorize methods.
    method !colorize-string( %vals --> Str ) {
        ("\x[1B][%s;%s;%sm%s\x[1B][0m").sprintf(|%vals<colors>, %vals<text>)
        but Colorizable
    }

    # Set the values for foreground, background, and mode. To allow consistency
    # (e.g., red text should be remain red unless its foreground is changed) in
    # the next colorize method invocation) through chained invocations,
    # precedence is given to an already existing color unless is being changed.
    method !set-values( %res, $foreground, $background, $mode --> Nil ) {
        %res<colors>[0] = do given (%res<colors>[0], $mode) -> ($old, $new) {
            when $old ~~ Int:D {
                $new.defined ?? self!mode($new) !! $old
            }
            default {
                $new.defined ?? self!mode($new) !! self!mode(default-mode)
            }
        }

        %res<colors>[1] = do given (%res<colors>[1], $foreground) -> ($old, $new) {
            when $old ~~ Int:D {
                $new.defined ?? self!foreground($new) !! $old
            }
            default {
                $new.defined ?? self!foreground($new) !! self!foreground(default-color)
            }
        }

        %res<colors>[2] = do given (%res<colors>[2], $background) -> ($old, $new) {
            when $old ~~ Int:D {
                $new.defined ?? self!background($new) !! $old
            }
            default {
                $new.defined ?? self!background($new) !! self!background(default-color)
            }
        }
    }

    # Return the integer value for a given color, if any. Otherwise, return
    # the type object Int.
    method !foreground( StrColor \color --> Int ) {
        return Int without color;
        my \colors = Color.enums;
        colors{color}.defined ?? colors{color} + 30 !! Int;
    }

    # Return the integer value for a given color, if any. Otherwise, return
    # the type object Int.
    method !background( StrColor \color --> Int ) {
        return Int without color;
        my \colors = Color.enums;
        colors{color}.defined ?? colors{color} + 40 !! Int;
    }

    # Return the integer value for a given mode, if any. Otherwise, return
    # the type object Int.
    method !mode( StrMode \mode --> Int ) {
        return Int without mode;
        my \modes = Mode.enums;
        modes{mode}.defined ?? modes{mode} !! Int;
    }

    # Scan string for ASCII escape codes.
    method !scan-string {
        my regex ansi-code {
            | \x[1B] '[' $<colors>=(<[0..9;]>+) 'm' $<text>=(.+) \x[1B] '[0m'
            | $<text>=(<-[\x[1B]]>+)
        }

        self!split-colors: self.Str.match(/<ansi-code>/)<ansi-code>
    }

    # Split colors from scan-string match. Return the text and its colors (if any).
    method !split-colors( $match --> Hash ) {
        my Int @colors[3] = ($match<colors> || '').split(';', :skip-empty)».Int;
        my Str $text      = $match<text>.Str;
        return %(:@colors, :$text)
    }

    # Make colors available as a methods.
    # See: https://docs.raku.org/type/Metamodel::MethodContainer#method_add_method
    method !color-methods( --> Nil ) {
        for self.colors -> \color {
            next if color eq default-color;

            unless self.can(color) {
                self.^add_method: color, method () { self.colorize: :fg(color) }
            }

            unless self.can('on-'~color) {
                self.^add_method: 'on-'~color, method () { self.colorize: :bg(color) }
            }
        }
    }

    # Make modes available as a methods.
    # See: https://docs.raku.org/type/Metamodel::MethodContainer#method_add_method
    method !mode-methods( --> Nil ) {
        for self.modes -> \mode {
            next if mode eq default-mode;
            unless self.can(mode) {
                self.^add_method: mode, method () { self.colorize: :mode(mode) }
            }
        }
    }
}

# END OF CODE

=begin pod

=head2 More examples

=head3 How to make rainbow-y strings?

An option is to create a subroutine that colorizes a string character
by character:

=begin code
sub rainbow( $str, :@only ) {
    sub rainbowize( @colors ) {
        $str.comb
        .batch(@colors.elems)
        .map({($_ Z @colors).map(-> ($ch, $fg) { ($ch does Colorizable).colorize($fg) }).join })
        .join
    }

    return rainbowize(@only) if @only;
    return rainbowize Color.enums.keys.list;
}

say rainbow "Hello, World!";
say rainbow "Hello, World!", :only[blue, red, yellow];
=end code

Another "I know what I'm doing" alternative is to implement a somewhat similar
routine right into the C<Str> class after composing C«Colorizable» into it:

=begin code
use MONKEY-TYPING;

augment class Str {
    also does Colorizable;

    method rainbow( $str : :@only ) {
        sub rainbowize( @colors ) {
            $str.comb
            .batch(@colors.elems)
            .map({($_ Z @colors).map(-> ($ch, $fg) { $ch.colorize($fg) }).join })
            .join
        }

        return rainbowize(@only) if @only;
        return rainbowize Color.enums.keys.list;
    }
}

say "Hello, World!".rainbow;
say "Hello, World!".rainbow: :only[blue, red, yellow];
=end code

=head2 Acknowledgement

This module is inspired by L<Michał Kalbarczyk|https://github.com/fazibear>'s
Ruby gem L<colorize|https://github.com/fazibear/colorize>.

=head2 Authors

Luis F. Uceta

=head2 License

You can use and distribute this module under the terms of the The Artistic
License 2.0. See the LICENSE file included in this distribution for complete
details.

The META6.json file of this distribution may be distributed and modified without
restrictions or attribution.

=end pod

