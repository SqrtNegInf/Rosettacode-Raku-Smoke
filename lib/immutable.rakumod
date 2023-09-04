use ValueList:ver<0.0.2>:auth<zef:lizmat>;
use ValueMap:ver<0.0.2>:auth<zef:lizmat>;

my constant L = ValueList;
my constant M = ValueMap;

my proto sub immutable(|) is export {*}
my multi sub immutable(@_)   { L.new: @_.map: &immutable }
my multi sub immutable(%_)   { M.new: %_.map: {.key => immutable .value} }
my multi sub immutable($_)   { $_ }
my multi sub immutable(**@_) { L.new: @_.map: &immutable }

=begin pod

=head1 NAME

immutable - Make data structures immutable

=head1 SYNOPSIS

=begin code :lang<raku>

use immutable;

my $ima := immutable @array;
my $imh := immutable %hash;
my $ims := immutable @array, %hash;

=end code

=head1 DESCRIPTION

immutable provides a single subroutine C<immutable> that will return an
immutable value-type data-structure for any data-structure given.

Inspired by a comment by Ralph Mellor on /r/rakulang.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/immutable . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
