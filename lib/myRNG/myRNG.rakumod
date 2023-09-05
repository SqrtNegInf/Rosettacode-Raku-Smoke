# this is splitmix64 from 'P/Pseudo-random_numbers_Splitmix64'

unit class myRNG;

has $!state;

submethod BUILD ( Int :$seed where * >= 0 = 1 ) { $!state = $seed }

method next-int {
    my $next = $!state = ($!state + 0x9e3779b97f4a7c15) +& (2⁶⁴ - 1);
    $next = ($next +^ ($next +> 30)) × 0xbf58476d1ce4e5b9 +& (2⁶⁴ - 1);
    $next = ($next +^ ($next +> 27)) × 0x94d049bb133111eb +& (2⁶⁴ - 1);
    ($next +^ ($next +> 31)) +& (2⁶⁴ - 1);
}

method next-rat { self.next-int / 2⁶⁴ }

# Knuth shuffle
sub pickall (@a is copy) is export {
    my $rng = myRNG.new( :seed(123456) );
    for 1 ..^ @a -> $n {
        my $k = (0 .. $n)[($n+1) × $rng.next-rat];
        $k == $n or @a[$k, $n] = @a[$n, $k];
    }
    @a
}
