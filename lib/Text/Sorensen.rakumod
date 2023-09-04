unit module Text::Sorensen:ver<0.0.1>:auth<github:thundergnat>;


# Sorensen-Dice
multi sorensen ($phrase, *@list, :$ge = .5) is export(:sorensen) {
    my $match = bi-gram $phrase;
    @list.race.map( {
        my $this = .&bi-gram;
        [2 * +($match ∩ $this) / ($match ⊎ $this), $_]
    } ).grep(*[0] >= $ge).sort({-.[0], ~.[1]})
}

multi sorensen ($phrase, %hash, :$ge = .5) is export(:sorensen) {
    my $match = bi-gram $phrase;
    %hash.race.map( {
        [2 * +($match ∩ .value) / ($match ⊎ .value), .key]
    } ).grep(*[0] >= $ge).sort({-.[0], ~.[1]})
}


# Aliases
our &sorenson is export(:sorenson) = &sorensen;
our &sdi      is export(:sdi)      = &sorensen;
our &dsc      is export(:dsc)      = &sorensen;
our &dice     is export(:dice)     = &sorensen;


# Jaccard
multi jaccard ($phrase, *@list, :$ge = .5) is export(:jaccard) {
    my $match = bi-gram $phrase;
    @list.race.map( {
        my $this = .&bi-gram;
        my \intersect = +($match ∩ $this);
        [intersect / (($match ⊎ $this) - intersect), $_]
    } ).grep(*[0] >= $ge).sort({-.[0], ~.[1]})
}

multi jaccard ($phrase, %hash, :$ge = .5) is export(:jaccard) {
    my $match = bi-gram $phrase;
    %hash.race.map( {
        my \intersect = +($match ∩ .value);
        [intersect / (($match ⊎ .value) - intersect), .key]
    } ).grep(*[0] >= $ge).sort({-.[0], ~.[1]})
}

# Always export
sub bi-gram (\these) is export(:MANDATORY) {
    Bag.new( flat these.fc.words.map: { .comb.rotor(2 => -1)».join } )
}


=begin pod
=head1 NAME
Text::Sorensen

Calculate the Sorensen-Dice or Jaccard similarity coefficient.

[![Build Status](https://travis-ci.org/thundergnat/Text-Sorensen.svg?branch=master)](https://travis-ci.org/thundergnat/Text-Sorensen)

=head1 SYNOPSIS

=begin code
    use Text::Sorensen :sorensen;

    # test a word against a small list
    say sorensen('compition', 'completion', 'competition');

    # ([0.777778 competition] [0.705882 completion])


    # or against a large one
    my %hash = './unixdict.txt'.IO.slurp.words.race.map: { $_ => .&bi-gram };

    .say for sorensen('compition', %hash).head(5);
    # [0.777778 competition]
    # [0.777778 compilation]
    # [0.777778 composition]
    # [0.705882 completion]
    # [0.7 decomposition]


    use Text::Sorensen :jaccard;

    .say for jaccard('compition', %hash).head(5);
    # [0.636364 competition]
    # [0.636364 compilation]
    # [0.636364 composition]
    # [0.545455 completion]
    # [0.538462 decomposition]


=end code

=head1 DESCRIPTION

Both Sorensen-Dice and Jaccard calculate a "similarity" between two tokenized
groups of items. They can be used to compare many different types of tokenized
objects; this module is optimized to do a text similarity calculation.

Both methods use a similar algorithm and, though they assign different weights,
return nearly identical relative coefficients, and may be readily converted
from one to the other.

You can easily convert back and forth:

    # J   (Jaccard index)
    # SDI (Sorensen-Dice index)

    J = SDI / (2 - SDI)

    SDI = 2 * J / (1 + J)


For both operations, each word / phrase is broken up into tokens for the
comparison. The most typical tokenizing scheme for text is to break the words up
into bi-grams: groups of two consecutive letters. For instance, the word 'differ'
would be tokenized to the group:

    'di', 'if', 'ff', 'fe', 'er'

This tokenized word is then compared to another tokenized word to calculate the
similarity.

The bi-gram routine case-folds the words before tokenizing so the comparison
routines ignore case differences.

A great deal of the work is spent in tokenizing the words. If you plan to do
multiple comparisons to a large group of words, it may be worthwhile to
pre-tokenize the word list to reduce the working time.

When using the module, you must specify which similarity routine(s) you want to
import. There are the two basic similarity algorithms and several built-in,
exported-on-demand aliases available.

Optionally exported similarity routines:

    :sorensen  --> sub sorensen() # traditional spelling
    :sorenson  --> sub sorenson() # alternate spelling
    :sdi       --> sub sdi()      # Sorensen-Dice index
    :dice      --> sub dice()     # let Dice have top billing for once
    :dsc       --> sub dsc()      # Dice similarity coefficient
    # All point to exactly the same routines behind the scenes.

    :jaccard   --> sub jaccard()  # Jaccard index

You'll need to import at least one similarity routine, or some combination, or
:ALL.

Always exported helper routine:

    sub bi-gram() # tokenize a word into a Bag of bi-grams


=head3 Sorensen-Dice

    use Text::Sorensen :sorensen; # or some other alias

Sorensen-Dice, named after botanists Thorvald Sørensen and Lee Raymond Dice,
measures the similarity of two groups by dividing twice the intersection token
count by the total token count of both groups.

     2 * +(@a ∩ @b) / (@a ⊎ @b)

The index is known by several names, Sorensen-Dice index is probably most
common, though Sorensen index and Dice's coefficient are also popular. Other
variations include the "similarity coefficient" or "index", such as Dice
similarity coefficient (DSC).

The module provides multi subs for different use cases.

For a one-off or low memory case, use:

    sorensen($word, @list, :$ge)

Where $word is the word to be compared against, @list is a list or array of
words to compare with $word, and :$ge is the minimum for the returned
coefficients (default .5). (It's the coefficients B<greater than or equal to>
.5).

The list of words will be tokenized, the coefficient calculated, entries with
coefficients lower than the :$ge threshold filtered out and the remaining list
sorted and returned. If you want all values to be returned, even ones that don't
match at all, you'll need to specify :ge(0). It's a little unintuitive at first
but can seriously reduce memory and time consumption for the common use case.

Each word comparison will return a 2 element array consisting of:

* the SDC from the :ge threshold (default .5) to 1 (identical).

* the word that was checked.

That works well but retokenizes the list every time it is invoked.

If you want to reuse a list several times to check against mutiple words, it may
be better to pre-tokenize the list and pass that to the coefficient function.

Use the module supplied, always exported, sub bi-gram() on each element to
pre-tokenize the list.

    # returns the tokenized word as a Bag
    my $tokens = bi-gram($word);


Save the list as a hash of word / tokens pairs, then pass that into the
coefficient function to avoid re-tokenizing every time. This is a nice
parallelizable operation so .race can really speed it up.

    my %hash = './unixdict.txt'.IO.slurp.words.race.map: { $_ => .&bi-gram };

    sorensen($word, %hash)

The returned list has results less than the :ge threshold filtered out and is
sorted by inverse coefficient (largest first) with a secondary alphabetical sort.

See the following. We compare the typo 'compition' against an entire dictionary,
filter out everything lower than .6 coefficient and return the sorted list.

    .say for sorensen('compition', %hash, :ge(.6));
    # [0.777778 competition]
    # [0.777778 compilation]
    # [0.777778 composition]
    # [0.705882 completion]
    # [0.7 decomposition]
    # [0.666667 compunction]
    # [0.666667 computation]



=head3 Jaccard

    use Text::Sorensen :jaccard;

The Jaccard index (named for botanist Paul Jaccard) is calculated very similarly
to the Sorensen-Dice index.

Instead of the intersection token count divided by the total token count, it is
the intersection token count divided by the difference between the total token
count and the intersection token count. (Intersection over difference rather
than intersection over sum).

    +(@a ∩ @b) / ( (@a ⊎ @b) - (@a ∩ @b) )

Jaccard coefficients tend to be even smaller than Sorensen-Dice but are similarly,
a ratio between 0 and 1.

Again, multis are provided for a one-off list:

    my @results = jaccard($word, @list, :$ge);

or a multi use hash.

    my @results =  jaccard($word, @hash, :$ge);

The exact same tokenizer is used for each, and the same efficiencies come into
play by pre-tokenizing dictionaries for repeated use.


    .say for jaccard('maintainence', %hash, :ge(.45));
    # [0.636364 maintain]
    # [0.615385 maintenance]




=head1 AUTHOR

2019 Steve Schulze aka thundergnat

This package is free software and is provided "as is" without express or implied
warranty.  You can redistribute it and/or modify it under the same terms as Perl
itself.

=head1 LICENSE

Licensed under The Artistic 2.0; see LICENSE.


=end pod
