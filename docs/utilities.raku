# re-usable one-liner utilities and snippets

# RC docs

;See also
:* [[oeis:A000000|OEIS:A000000]]


#==== elide middle of something long

sub abbr ($_) { .chars < 41 ?? $_ !! .substr(0,20) ~ '…' ~ .substr(*-20) ~ " ({.chars} digits)" }

#==== host-specific

if qx/uname -a/ ~~ /'Mac-Pro'/
if qx/uname -a/ ~~ /'iMac'/
if qx/uname -a/ ~~ /'Ubuntu'/
