#!/usr/bin/env raku
#u# https://rosettacode.org/wiki/xx
#t# inprogress
#c# 2023-0x-xx >RC
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
#is @res.join('').lc.subst(/<ws>/, '', :g), $ref.lc.subst(/<ws>/, '', :g);
#is @res.join("\n"), chomp $*VM ~~ /jvm/ ?? $jvm !! $moar;
#is @res.join("\n"), chomp $*VM ~~ /jvm/ ?? $jvm !! $*IN.t ?? $moar-terminal !! $moar-cronjob;
is @res.join("\n"), chomp $ref;

=finish

=={{header|Raku}}==
<syntaxhighlight lang="perl6" line>
</syntaxhighlight>
{{out}}
<pre style="height:20ex">
</pre>
[[File:xx|300px|thumb|right]]
[https://github.com/SqrtNegInf/Rosettacode-Raku-Smoke/blob/master/ref/xx xx]
