unit module Abbreviations;

enum Out-type is export <S L AH AL H>;

# define  "aliases" for convenience
our &abbrevs is export         = &abbreviations;
our &abbrev  is export         = &abbreviations;
our &abbre   is export(:abbre) = &abbreviations;
our &abbr    is export(:abbr)  = &abbreviations;
our &abb     is export(:abb)   = &abbreviations;
our &ab      is export(:ab)    = &abbreviations;
our &a       is export(:a)     = &abbreviations;
sub abbreviations($word-set,
                  Out-type :$out-type = H,
                  :$lower-case,
                  :$debug,
                 ) is export {
    # Given a set of words, determine the shortest unique abbreviation
    # for each word.

    my @abbrev-words;
    my @input-order; # holds the original order before any lower-casing
    my @input-order-lower-case;

    # determine the input type and generate the input word lists accordingly
    if $word-set ~~ Str {
        @abbrev-words = $word-set.words;
        @input-order  = @abbrev-words;
    }
    elsif $word-set ~~ List {
        @abbrev-words = @($word-set);
        @input-order  = @abbrev-words;
    }
    else {
        die "FATAL: Cannot handle word set format '{$word-set.^name}'";
    }

    if not @abbrev-words.elems {
        die "FATAL: Empty input word set.";
    }

    # remove any dups
    @abbrev-words .= unique;
    @input-order  = @abbrev-words;

    if $lower-case {
        $_ .= lc for @abbrev-words;
        @abbrev-words .= unique;
        @input-order-lower-case = @abbrev-words;
    }

    # A default returned Hash has the input words as keys whose values are
    # a sorted list of strings of their unique shorter abbreviations, if
    # any. Note all sorts use sub 'sort-list'.

    my %group; # top key is a subgroup based on the first character of the word
    # classify all words by first character
    if $debug {
        note qq:to/HERE/;
        DEBUG: classifying groups. Number of \@abbrev-words is {@abbrev-words.elems}
               dumping \@abbrev-words: '{@abbrev-words.raku}'";
        HERE
    }

    for @abbrev-words -> $w {
        note "DEBUG: classifying groups for word '$w'" if $debug;
        my $c = $w.comb[0];
        note "DEBUG: considering character '$c'" if $debug;
        if %group{$c}:exists {
            %group{$c}.push: $w;
        }
        else {
            %group{$c} = [];
            %group{$c}.push: $w;
        }
    }
    note "DEBUG: finished classifying groups..." if $debug;

    # At this point we have:
    #   + thrown an exception for an empty input word set.
    #   + down-cased the input words if option :lower-case was used
    #   + removed dups from the input word set
    #   + divided the input string into leading character case type

    note "DEBUG: ready to assemble groups" if $debug;

    my %ow; # hash to hold the input words as keys and their abbreviations as sorted lists
    for %group.keys -> $group {
        note "DEBUG: considering group '$group'" if $debug;
        get-abbrevs $group, :%ow, :%group;
    }

    note "DEBUG: dumping \%group: '{%group.raku}'" if $debug;
    note "DEBUG: dumping \%ow: '{%ow.raku}'" if $debug;

    #note "DEBUG: early exit in sub abbrevs"; exit;

    # the hash output is %ow and ready to go
    return %ow if $out-type ~~ H; # 'Hash'

    # use the default hash to assemble other output formats
    my @ow;
    for %ow.kv -> $k, $v {
        @ow.push: $k;
        @ow.push($_) for @($v);
    }

    # the list and string output formats will have all words (keys) and abbreviation
    # sorted by default then length (shortest first)
    @ow .= unique;
    @ow = sort-list @ow;

    return @ow if $out-type ~~ L; # 'List'
    return @ow.join(' ') if $out-type ~~ S; # 'String';

    if $out-type ~~ AH {
        #=== Output hash converted to AbbrevHash:
        # The AbbrevHash is keyed by all abbreviations for
        # each word and its value is that word.
        my %ah;
        for %ow.kv -> $w, $v {
            for @($v) -> $a {
                die "FATAL: Unexpected dup abbev '$a' for word '$w'" if %ah{$a}:exists;
                %ah{$a} = $w;
            }
        }
        return %ah;
    }

    if $out-type ~~ AL {
        #=== Output hash converted to AbbrevList:
        # The AbbrevList is the list of the min abbreviations for
        # each word in the original input order.
        my @al;
        my @in = @abbrev-words;
        for @in -> $w {
            # for each word, add its min abbrev to the list
            my $m = @(%ow{$w})[0];
            @al.push: $m;
        }
        note "DEBUG: in words: {@in}" if $debug;
        note "DEBUG:  abbrevs: {@al}" if $debug;
        return @al;
    }

} # end sub abbreviations

sub get-abbrevs($group, :%ow, :%group, :$debug) {
    my @input-words = @(%group{$group});

    # Get the min number of characters needed to have a unique
    # abbreviation.  If the number of characters in a word is equal or
    # less, then it has no abbreviation.
    my $min-chars = auto-abbreviate @input-words;

    note "DEBUG: get-abbrevs, \$group $group, word list: '{@input-words.raku}'" if $debug;
    note "DEBUG: get-abbrevs, min abbrev chars: $min-chars" if $debug;

    WORD: for @input-words -> $w {
        # %ow should NOT have this word yet
        die "FATAL: Unexpected duplicate input word '$w' in group '$group'. \%group: {say %group.raku}"
            if %ow{$w}:exists;

        my $nc = $w.chars;

        # any abbreviations?
        if $nc <= $min-chars {
            %ow{$w} = [$w];
            next WORD;
        }

        my @a;
        # Handle the abbreviations
        my $len = $min-chars;
        while $len <= $nc {
            # using $nc as the max length will include the word as the last abbreviation
            my $a = $w.substr(0, $len);
            @a.push: $a;
            ++$len;
        }

        @a .= unique;
        # sort the list two ways
        @a = sort-list @a;

        # add the list to the key
        %ow{$w} = @a;

        note "DEBUG: end of a key fill in sub get-abbrevs" if $debug;
    }

} # end sub get-abbrevs

sub auto-abbreviate(@words) is export(:auto) {
    # Given a string consisting of space-separated words, return the
    # minimum number of characters to abbreviate the set.  WARNING:
    # Inf is returned if there are duplicate words in the string, so
    # the user is warned to avoid that or catch the error exception.
    #
    # Source: http://rosettacode.org/wiki/Abbreviations,_automatic#Raku
    # Author: @thundergnat

    return Nil unless @words; # The caller should of taken care of that.

    # The normal situation:
    return $_ if @words>>.substr(0, $_).Set == @words for 1 .. @words>>.chars.max;

    # There are duplicate words in the input word set.
    # NOTE: Our caller should have taken care of that.
    return Inf;
} # end sub auto-abbreviate

sub sort-list(@list is copy, :$longest-first) is export(:auto, :sort) {
    # always sort by standard sort first
    @list .= sort;
    return @list.sort({$^b.chars cmp $^a.chars}) if $longest-first;
    # sort by shortest word first
    @list.sort({$^a.chars cmp $^b.chars});
}
