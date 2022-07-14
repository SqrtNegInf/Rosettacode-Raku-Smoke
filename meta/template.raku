#!/usr/bin/env raku
#u# http://rosettacode.org/wiki/xx
#t# inprogress
#c# 2022-xx-xx >RC
#m# MOAR: OK
#j#  JVM: OK

#srand 123456;

my @res;

# code goes here

.say for @res;

my $ref = qq:to/END/;
END

use Test;
#my $ref = $*VM ~~ /jvm/ ?? $jvm !! $moar;
#is @res.join('').subst(/<ws>/, '', :g), $ref.subst(/<ws>/, '', :g);$
is @res.join("\n"), chomp $ref;

=finish

=={{header|Raku}}==
<lang perl6>
</lang>
{{out}}
<pre style="height:20ex">
</pre>
[https://github.com/SqrtNegInf/Rosettacode-Raku-Smoke/blob/master/ref/xx xx]
