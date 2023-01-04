# re-usable one-liner utilities

# RC docs

;See also
:* [[oeis:A000000|OEIS:A000000]]


#==== elide middle of something long

sub abbr ($_) { .chars < 41 ?? $_ !! .substr(0,20) ~ '…' ~ .substr(*-20) ~ " ({.chars} digits)" }
