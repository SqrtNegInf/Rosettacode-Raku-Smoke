use v6;

use NativeLibs:ver<0.0.9>;
#use NativeLibs:ver<0.0.8+>:auth<github:salortiz>;

my $Lib;

INIT
{
    for v9, v8, v7 -> $version
    {
        my $lib = $*VM.platform-library-name('primesieve'.IO, :$version);
        last if $Lib = NativeLibs::Loader.load($lib.basename)
    }
    fail "No primesieve library" unless $Lib
}

constant PRIMESIEVE_ERROR = 18446744073709551615;

enum PRIMESIEVE <SHORT_PRIMES USHORT_PRIMES INT_PRIMES UINT_PRIMES
  LONG_PRIMES ULONG_PRIMES LONGLONG_PRIMES ULONGLONG_PRIMES
  INT16_PRIMES UINT16_PRIMES INT32_PRIMES UINT32_PRIMES INT64_PRIMES
  UINT64_PRIMES>;

class Math::Primesieve::iterator-struct is repr('CStruct')
{
    has size_t $.i;
    has size_t $.last_idx;
    has uint64 $.start;
    has uint64 $.stop;
    has uint64 $.stop_hint;
    has uint64 $.dist;
    has CArray[uint64] $.primes;
    has Pointer $.vector;
    has Pointer $.primeGenerator;
    has int32 $.is_error;

    sub primesieve_init(Math::Primesieve::iterator-struct)
        is native {*}

    sub primesieve_free_iterator(Math::Primesieve::iterator-struct)
        is native {*}

    sub primesieve_skipto(Math::Primesieve::iterator-struct, uint64, uint64)
        is native {*}

    sub primesieve_generate_next_primes(Math::Primesieve::iterator-struct)
        is native {*}

    sub primesieve_generate_prev_primes(Math::Primesieve::iterator-struct)
        is native {*}

    sub primesieve_get_max_stop() returns uint64
        is native {*}

    method init()
    {
        primesieve_init(self);
    }

    method skipto(uint64 $start, uint64 $stop-hint = primesieve_get_max_stop)
    {
        primesieve_skipto(self, $start, $stop-hint);
    }

    method next()
    {
        primesieve_generate_next_primes(self) if $!i++ == $!last_idx;
        $!primes[$!i]
    }

    method prev()
    {
        primesieve_generate_prev_primes(self) if $!i-- == 0;
        $!primes[$!i]
    }

    method free()
    {
        primesieve_free_iterator($_) with self;
    }
}

class Math::Primesieve::iterator
{
    has $.raw;

    method new(Int $start?)
    {
        my $self = self.bless(raw => buf8.allocate(
            nativesizeof(Math::Primesieve::iterator-struct)));
        $self.iterator.init;
        $self.skipto($start) with $start;
        $self;
    }

    method iterator() { nativecast(Math::Primesieve::iterator-struct, $!raw) }

    method skipto(|c) { self.iterator.skipto(|c) }

    method next() { self.iterator.next }

    method prev() { self.iterator.prev }

    method DESTROY()
    {
        self.iterator.free;
    }
}

class X::Math::Primesieve is Exception
{
    method message() { 'Math::Primesieve error' }
}

class Math::Primesieve does Positional
{
    sub primesieve_version() returns Str is native {*}

    sub primesieve_generate_primes(uint64, uint64, size_t is rw, int32)
        returns Pointer is native {*}

    sub primesieve_generate_n_primes(uint64, uint64, int32)
        returns Pointer is native {*}

    sub primesieve_nth_prime(int64, uint64)
        returns uint64 is native {*}

    sub primesieve_count_primes(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_count_twins(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_count_triplets(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_count_quadruplets(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_count_quintuplets(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_count_sextuplets(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_print_primes(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_print_twins(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_print_triplets(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_print_quadruplets(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_print_quintuplets(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_print_sextuplets(uint64, uint64)
        returns uint64 is native {*}

    sub primesieve_get_max_stop() returns uint64 is native {*}

    sub primesieve_get_sieve_size() returns int32 is native {*}

    sub primesieve_get_num_threads() returns int32 is native {*}

    sub primesieve_set_sieve_size(int32) is native {*}

    sub primesieve_set_num_threads(int32) is native {*}

    sub primesieve_free(Pointer) is native {*}

    method BUILD(:$num-threads, :$sieve-size)
    {
        primesieve_set_num_threads($num-threads) with $num-threads;

        primesieve_set_sieve_size($sieve-size) with $sieve-size;
    }

    method version() { primesieve_version }

    method max-stop() { primesieve_get_max_stop }

    method sieve-size($sieve-size?)
    {
        primesieve_set_sieve_size($sieve-size) with $sieve-size;

        primesieve_get_sieve_size;
    }

    method num-threads($num-threads?)
    {
        primesieve_set_num_threads($num-threads) with $num-threads;

        primesieve_get_num_threads;
    }

    method primes(UInt $start is copy, UInt $stop is copy = 0)
    {
        my size_t $size;

        unless $stop
        {
            $stop = $start;
            $start = 0;
        }

        my $p = primesieve_generate_primes($start, $stop, $size, UINT64_PRIMES)
            or die X::Math::Primesieve.new;

        my @ret = nativecast(CArray[uint64], $p)[0 ..^ $size];

        primesieve_free($p);

        @ret;
    }

    method n-primes(UInt $n, UInt $start = 0)
    {
        my $p = primesieve_generate_n_primes($n, $start, UINT64_PRIMES)
            or die X::Math::Primesieve.new;

        my @ret = nativecast(CArray[uint64], $p)[0 ..^ $n];

        primesieve_free($p);

        @ret;
    }

    method nth-prime(Int $n, UInt $start = 0)
    {
        primesieve_nth_prime($n, $start)
    }

    method AT-POS($n) { self.nth-prime($n) }

    method count(UInt $start is copy, UInt $stop is copy = 0,
                 :$twins, :$triplets, :$quadruplets, :$quintuplets, :$sextuplets)
    {
        unless $stop
        {
            $stop = $start;
            $start = 0;
        }

        return primesieve_count_twins($start, $stop)       if $twins;
        return primesieve_count_triplets($start, $stop)    if $triplets;
        return primesieve_count_quadruplets($start, $stop) if $quadruplets;
        return primesieve_count_quintuplets($start, $stop) if $quintuplets;
        return primesieve_count_sextuplets($start, $stop)  if $sextuplets;
        primesieve_count_primes($start, $stop)
    }

    method print(UInt $start is copy, UInt $stop is copy = 0,
                 :$twins, :$triplets, :$quadruplets,
                 :$quintuplets, :$sextuplets)
    {
        unless $stop
        {
            $stop = $start;
            $start = 0;
        }

        return primesieve_print_twins($start, $stop)       if $twins;
        return primesieve_print_triplets($start, $stop)    if $triplets;
        return primesieve_print_quadruplets($start, $stop) if $quadruplets;
        return primesieve_print_quintuplets($start, $stop) if $quintuplets;
        return primesieve_print_sextuplets($start, $stop)  if $sextuplets;
        primesieve_print_primes($start, $stop)
    }
}
