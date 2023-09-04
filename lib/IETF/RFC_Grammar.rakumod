unit class IETF::RFC_Grammar;

# Thanks in part to Aaron Sherman
# and his article http://essays.ajs.com/2010/05/writing-perl-6-uri-module.html
# for inspiring this.

# below should be constant when implemented ...
my %rfc_grammar_build = (
     'rfc3986' => 'IETF::RFC_Grammar::URI'
);
my %rfc_grammar;

# Hack to give hint to ufo/Panda to build in the right order.
# remove some day when module builders are upgraded
use IETF::RFC_Grammar::URI;

has $.rfc;
has $.grammar;
has $.parse_result;

method parse($parse_str) {
    $!parse_result = $!grammar.parse($parse_str);
}

method subparse($parse_str) {
    $!parse_result = $!grammar.subparse($parse_str);
}


submethod BUILD(:$!rfc, :$!grammar) {}

method new(Str $rfc, $grammar?) {
    my $init_grammar = $grammar;

    if (
        (! $init_grammar.can('parse'))  and
        %rfc_grammar_build{$rfc}:exists;
    ) {
        unless %rfc_grammar{$rfc}:exists {
            my $module = %rfc_grammar_build{$rfc};
            # less disruptive fix to RT126390
            unless ($rfc eq 'rfc3986') { require ::($module); }
            %rfc_grammar{$rfc} = ::($module);
        }
        $init_grammar = %rfc_grammar{$rfc};
    }
    if (! $init_grammar.can('parse')) {
        die "Need either rfc with known grammar or grammar";
    }

   return self.bless(rfc => $rfc, grammar => $init_grammar);
}

