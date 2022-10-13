#!/bin/sh
# results for: v2022.07-63-g82d4c17c0
# note that invoking as shell script gives different results than running each snippet on command-line
# (cf 'srand-at-start')

# A: varies, of course
raku -e 'my $x = <A B C D>; say "varies " ~ $x.roll(10);'

# B: (1)
raku -e 'my $x = <A B C D>; srand 12345; say "ans 1  " ~ $x.roll(10);'

# C: (2)
raku -e 'my $x = <A B C D>; say "varies " ~ $x.roll(10); srand 12345; say "ans 2  " ~ $x.roll(10);'

# D: (1)
raku -e 'my $x = <A B C D>; srand 12345; sub foo($n) { say "ans 1  " ~ $x.roll($n) }; foo(10);'

# E: (1)
raku -e 'my $x = <A B C D>; sub boo($n) { srand 12345; say "ans 1  " ~ $x.roll($n) }; boo(10);'

# F: (3)
raku -e 'my $x = <A B C D>; sub MAIN () { srand 12345; say "ans 3  " ~ $x.roll(10) }'

# G: (4)
raku -e 'my $x = <A B C D>; srand 12345; sub MAIN () { say "ans 4  " ~ $x.roll(10) }'
