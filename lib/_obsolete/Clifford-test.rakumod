# 2019-10-25 with JVM, failng one way:

#no precompilation;
#use lib 'lib';
unit module Clifford;
use MultiVector;
use MultiVector::BitEncoded::Optimized;
my $foo = MultiVector::BitEncoded::Optimized.new("no");
dd $foo;
