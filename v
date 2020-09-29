#!/usr/bin/env raku
#u# http://rosettacode.org/wiki/v
#c# 2020-09-28 <RC
#m# MOAR: BROKEN OK
#j# JVM:  BROKEN OK
#  {{Works with|rakudo|2020.09}} or {{broken|Raku}}  

my @res;



END

.say for @res;
my $ref = q:to/END/;

use Test;
#my $ref = $*VM ~~ /jvm/ ?? $jvm !! $moar;
#is @res.join("\n"), chomp $ref;
