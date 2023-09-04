# 2022-01-26
# now generating 'Segmentation fault'

# 2019-10-25 with JVM, failng one way:
# 'Clifford::MV' cannot inherit from 'MultiVector::BitEncoded::Optimized' because it is unknown.
# at /Users/dhoekman/perl6/Rosetta-Code/lib/Clifford.rakumod (Clifford):6
#
# or if I remove the alias, another:
# An exception occurred while evaluating a constant
#  at /Users/dhoekman/perl6/Rosetta-Code/lib/Clifford.rakumod (Clifford):15
#  Exception details:
#    Could not find symbol '&Optimized'
#      in block  at /Users/dhoekman/perl6/Rosetta-Code/lib/Clifford.rakumod (Clifford) line 15

#no precompilation;
#use lib 'lib';
unit module Clifford;
use MultiVector;
use MultiVector::BitEncoded::Optimized;
subset Vector of MultiVector where .grades.all == 1;

#class MV is MultiVector::BitEncoded::Optimized {}  # just an alias
our @e is export = map { MultiVector::BitEncoded::Optimized.new("e$_") }, ^Inf;
our @ē is export = map { MultiVector::BitEncoded::Optimized.new("ē$_") }, ^Inf;
our constant no is export = MultiVector::BitEncoded::Optimized.new("no");
our constant ni is export = MultiVector::BitEncoded::Optimized.new("ni");

# ADDITION
multi infix:<+>(MultiVector $A, Real $x) returns MultiVector is export { $A.add($x) }
multi infix:<+>(Real $x, MultiVector $B) returns MultiVector is export { $B.add($x) }
multi infix:<+>(MultiVector $A, MultiVector $B) returns MultiVector is export { $A.add($B) }

# MULTIPLICATION
multi infix:<*>(Real $s, MultiVector $A) returns MultiVector is export { $A.scale($s) }
multi infix:<*>(MultiVector $A, Real $s) returns MultiVector is export { $A.scale($s) }
multi infix:<*>(MultiVector $A, MultiVector $B) returns MultiVector is export { $A.gp($B) }
multi infix:</>(MultiVector $A, Real $s) returns MultiVector is export { $A.scale(1/$s) }
multi infix:</>($x, Vector $A) returns MultiVector is export { $x*$A/($A*$A).Real }

# SUBSTRACTION
multi prefix:<->(MultiVector $A) returns MultiVector is export { return -1 * $A }
multi infix:<->(MultiVector $A, MultiVector $B) returns MultiVector is export { $A + -$B }
multi infix:<->(MultiVector $A, Real $s) returns MultiVector is export { $A + -$s }
multi infix:<->(Real $s, MultiVector $A) returns MultiVector is export { $s + -$A }

# EXPONENTIATION
multi infix:<**>(MultiVector $A where $A !== 0, 0) returns MultiVector is export { return $A.new: 1 }
multi infix:<**>(MultiVector $A, 1) returns MultiVector is export { return $A.clone }
multi infix:<**>(MultiVector $A, 2) returns MultiVector is export { return $A * $A }
multi infix:<**>(MultiVector $A, UInt $n where $n %% 2) returns MultiVector is export {
    return ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(MultiVector $A, UInt $n) returns MultiVector is export {
    return $A * ($A ** ($n div 2)) ** 2;
}
multi infix:<**>(Vector $V, 2) returns Real is export { ($V*$V).narrow }

# COMPARISON
multi infix:<==>(MultiVector $A, MultiVector $B) returns Bool is export { $A - $B == 0 }
multi infix:<==>(Real $x, MultiVector $A) returns Bool is export { $A == $x }
multi infix:<==>(MultiVector $A, Real $x) returns Bool is export {
    my $narrowed = $A.narrow;
    $narrowed ~~ Real and $narrowed == $x;
}

# INVOLUTIONS
sub postfix:<~>(MultiVector $A) returns MultiVector is export { $A.reversion }
sub postfix:<^>(MultiVector $A) returns MultiVector is export { $A.involution }

# DERIVED PRODUCTS
sub infix:<·>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.ip($B) }
sub infix:<∧>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.op($B) }
sub infix:<⌋>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.lc($B) }
sub infix:<⌊>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.rc($B) }
sub infix:<∗>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.sp($B) }
#sub infix:<×>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { 1/2*($A*$B - $B*$A) }
sub infix:<∙>(MultiVector $A, MultiVector $B) returns MultiVector is tighter(&infix:<*>) is export { $A.dp($B) }
