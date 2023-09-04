unit module Text::MiscUtils::Layout;


# Needed for colorstrip() to handle laying out already-colored text
use Terminal::ANSIColor;


#| Calculate monospaced width of a single line of text, ignoring ANSI colors
#  XXXX: Does not handle cursor-movement control characters such as TAB
sub duospace-width(Str:D $text, Bool :$wide-context = False) is export {
    # OLD APPROXIMATION, simply counting NFG characters
    # colorstrip($text).chars

    # Unicode TR11 approximation, based on legacy character set display width
    # compatibility and General_Category visibility -- first strip out ANSI
    # codes and likely invisible/non-spacing Unicode characters, then sum the
    # counts of remaining characters in each width category
    my %ignore is Set = < Mn Mc Me Cc Cf Cs Co Cn >;
    my $counts = colorstrip($text).ords
                 .grep({ !%ignore{.uniprop} })
                 .map({ .uniprop('East_Asian_Width') }).Bag;

    $counts<N> + $counts<Na> + $counts<H>   # Generally narrow
    + 2 * ($counts<F> + $counts<W>)         # Always wide
    + (1 + $wide-context) * $counts<A>      # Context-dependent
}


#| Wrap a single line of (possibly ANSI colored) $text to a given $width
#  Returns an array of wrapped lines with no trailing newlines.
#  Doesn't try to split single words wider than $width.
#  Tries to maintain any leading indent, but does not account for tabs.
sub text-wrap(UInt:D $width is copy, Str:D $text is copy) is export {
    $text    .= trim-trailing;
    $width max= 1;

    return [''] if $text.match(/^\s*$/);

    my @pieces = $text.split(/\s+/);

    my $indent = '';
    if !@pieces[0] {
        @pieces.shift;
        $indent = ~$text.match(/^(\s+)/)[0];
    }
    my $ilen = duospace-width($indent);

    my @lines;
    my $cur = 0;
    while @pieces.shift -> $piece {
        my $len = duospace-width($piece);
        if !$cur || $cur + $len + 1 > $width {
            @lines.push: "$indent$piece";
            $cur = $ilen + $len;
        }
        else {
            @lines[*-1] ~= ' ' ~ $piece;
            $cur += $len + 1;
        }
    }

    @lines
}


#| Render an array of (possibly ANSI colored) multi-line text blocks horizontally into $width-sized columns
#  Thus (5, "12\n34\n", "abc\ndefg\nhi", :sep<|>) --> "12   |abc  \n34   |defg \n     |hi   "
sub text-columns(UInt:D $width, *@blocks, Str:D :$sep = '  ', Bool :$force-wrap) is export {
    my @fitted;
    for @blocks -> $block {
        @fitted.push: $block.split(/\n/).flatmap({
            duospace-width($_) <= $width && !$force-wrap ?? $_ !! text-wrap($width, $_)
        });
    }

    # See http://irclog.perlgeek.de/perl6/2016-07-13#i_12834465
    # for discussion about the ragged transpose operation
    my $max = @fitted.map(*.elems).max;
    my @rows = zip @fitted.map(*.[^$max]);

    @rows.map({ .map({ my $row = $^a || ''; $row ~ ' ' x max(0, $width - duospace-width($row)) }).join($sep) }).join("\n")
}


#| Render an array of (possibly ANSI colored) text cells into one evenly spaced line justified to $width
#  Adds at least one space between the cells, even if it makes the line longer than $width.
sub evenly-spaced(UInt:D $width, *@cells) is export {
    my @c = @cells.grep: *.chars;
    return '' unless @c;

    my $gaps  = max 1, @c - 1;
    my $chars = @c.map({ duospace-width($_) }).sum;
    my $pad   = ($width - $chars) / $gaps;

    my $line = '';
    my $used = 0;
    for @c.kv -> $col, $text {
        my $spaces = max 1, round($pad * ($col + 1) - $used);
        $used += $spaces;
        $line ~= $text;
        $line ~= ' ' x $spaces unless $col == @c.end;
    }

    $line
}
