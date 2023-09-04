use v6;

unit module Lingua::EN::Sentence:auth<LlamaRider>;
my $VERBOSE = 0;
my Str $EOS = "__EOS__";
my Str $ELLIPSIS = "__ELLIPSIS__";
my Str $TWO_DOTS = "__TWO_DOTS__";
my Str $DOT = "__DOT__";

my token termpunct { <[.?!]> }
my token AP { [<['"»)\]}]>]? } ## AFTER PUNCTUATION
my token PAP { <termpunct> <AP> };
my token alphad { <.alpha>|'-' }


# NOTE: all abbreviations are case sensitive, specify lower case first letter only when needed
my @PEOPLE = <Mr Mrs Ms Dr Prof Mme Mgr Msgr Sen Sens Rep Reps Gov Atty Artts Supt Insp Const Det Rev Revd Ald Rt Hon>;
my @TITLE_SUFFIXES = <PhD Jr Jnr Sn Snr Esq MD LLB>;
my @ARMY = <Col Gen Lt Cm?dr Adm Capt Sgt Cpl Maj Pte>;
my @INSTITUTES = <Dept Univ Assn Bros>;
my @COMPANIES = <Inc Pty Ltd Co Corp>;
my @PLACES = <Arc Al Ave Blv Blvd Cl Ct Cres Dr Exp Expy Fwy Fy Hwy Hway La Pd Pde Pl Plz Rd St Tce
 dist mt ft 
 Ala Ariz Ark Cal Calif Col Colo Conn 
 Del Fed Fla Ga Ida Id Ill Ind Ia Kan Kans Ken Ky La Md Is Mass 
 Mich Minn Miss Mo Mont Neb Nebr Nev Mex Okla Ok Ore Penna Penn Pa 
 Dak Tenn Tex Ut Vt Va Wash Wis Wisc Wy Wyo USAFA 
 Alta Man Ont Qué Sask Yuk 
 Aust Vic Qld Tas>; # Me conflicts with me
 
my @MATH = <Fig fig eq sec i'.'e e'.'g P'-'a'.'s cf Thm Def Conj resp>;
my @MONTHS = <Jan Feb Mar Apr May Jun Jul Aug Sep Sept Oct Nov Dec >;
my @MISC = <vs no esp>; # etc causes more problems than it solves

my  Str @ABBREVIATIONS = (@PEOPLE, @TITLE_SUFFIXES, @ARMY, @INSTITUTES, @COMPANIES, @PLACES, @MONTHS, @MATH, @MISC).flat;

sub add_acronyms(*@new_acronyms) is export {
  @ABBREVIATIONS.append: @new_acronyms;
 }
sub get_acronyms() is export {return @ABBREVIATIONS;}
sub set_acronyms(*@new_acronyms) is export {
  @ABBREVIATIONS=@new_acronyms;
}
sub get_EOS() is export {return $EOS;}
sub set_EOS(Str $end_marker) is export {$EOS=$end_marker;}

#------------------------------------------------------------------------------
#`[
sentences - takes text input and splits it into sentences.
Firstly, letters and full stops sequences that don't end a sentence
are tranformed into another symbol.
A regular expression  cuts the text into sentences, and then a list
of rules is applied on the marked text in order to fix end-of-sentence
markings in places which are not indeed end-of-sentence.
]

sub sentences(Str $text) is export {
  my @sentences;
  if ($text.defined) {
    my $marked_text = mark_up_false_stops($text);
    $VERBOSE and say "MARKED UP SENTENCES\n",$marked_text;
    
    my ($quoteless_text, Array[Str] $quotes) = hide_quotes($marked_text);
    # $VERBOSE and say "QUOTELESS TEXT\n",$quoteless_text;
    my $final_text = first_sentence_breaking($quoteless_text);
    $VERBOSE and say "FINAL TEXT\n",$final_text;
    my $fixed_text = remove_false_end_of_sentence($final_text);
    $VERBOSE and say "FIXED TEXT\n", $fixed_text;
    my $quoteful_text = show_quotes($fixed_text, $quotes);
    @sentences = clean_sentences(split(/$EOS/,$quoteful_text));
   
    remove_markup(@sentences);
    
  }
  return @sentences;
}

#------------------------------------------------------------------------------
# augmenting the default Str class with a .sentences methods, 
# for extra convenience. Sweet!
#------------------------------------------------------------------------------
use MONKEY-TYPING;
use MONKEY-SEE-NO-EVAL;
augment class Str { method sentences { return sentences(self); } }

#==============================================================================
#
# Private methods
#
#==============================================================================

sub mark_up_false_stops(Str $request) {
  my $text = $request;
  $text ~~ s:g/'. .'/$TWO_DOTS/;
  $text ~~ s:g/'...'/$ELLIPSIS/;
  
  # mark integers ending with a . followed by space and lowercase letter such a 'point 12. states...'
  $text ~~ s:g/(<space>)(<digit>+)'.'(<space><lower>)/$0$1$DOT$2/;
  
  # Mark up acromyms
  $text ~~ s:g/<space>(<alpha>)'.'(<alpha>)'.'(<alpha>)'.'(<alpha>)'.'(','?)<space>/ $0$DOT$1$DOT$2$DOT$3$DOT$4 /; # A.B.C.D. optionally followed by ,
  $text ~~ s:g/<space>(<alpha>)'.'(<alpha>)'.'(<alpha>)'.'(','?)<space>/ $0$DOT$1$DOT$2$DOT$3 /; # such as U.S.A.
  $text ~~ s:g/<space>(<alpha>)'.'(<alpha>)'.'(','?)<space>/ $0$DOT$1$DOT$2 /; # such as U.K. Also handles 2 initials in a persons name
  
  # First mark dots belonging to a persons' initials such as Mr A. Smith
  my @TITLE = <Mr Mrs Ms Dr Prof Mme Mgr Msgr>;  
  $text ~~ s:g/
  (
  @TITLE
  '.'?
  <space>
  )
  (<upper>)'.'  # initial with dot
  (
  <space>
  <upper>  # surname
  <alpha>**{2..12}
  )
  /$0$1$DOT$2/;
  
  # Now convert dot in any abbreivations including titles such as Mr. Pty. Ariz.  etc  
  for @ABBREVIATIONS -> $abbrev {
    $text ~~ s:g/
    (<space>)($abbrev)'.'(<space>)
    /$0$1$DOT$2/;
  }   
   
  return $text;
}

sub hide_quotes(Str $request) {
  my $text = $request;
  my Str @quotes;
  while ($text ~~ s/('"' <-["]>+ '"')/XXXQUOTELESSXXX/) {
    @quotes.push($0.Str);
  }
  return ($text,@quotes);
}


sub first_sentence_breaking(Str $request) {
  my $text = $request;
  $text ~~ s:g/\n<.space>*\n/$EOS/;
  $text ~~ s:g/(<&PAP><.space>)/$0$EOS/;
  $text ~~ s:g/(<.space><.alpha><&termpunct>)/$0$EOS/; # break also when single letter comes before punc.
  $text ~~ s:g/(<.alpha><.space><&termpunct>)/$0$EOS/; # Typos such as " arrived .Then "
  return $text;
}

sub remove_false_end_of_sentence(Str $request) {
  my $s = $request;
  
  # don't split after a white-space followed by a single letter followed
  # by a dot followed by another white space
  $s ~~ s:g/(<.space><.alpha>'.'<.space>+)$EOS/$0/;

  # fix "." "?" "!"
  # TO DO, still needed with hidequotes??
  $s ~~ s:g/(<['"]><&termpunct><['"]><.space>)$EOS/$0/;
  # don't break after quote unless its a capital letter.
  # TODO: Need to work on balanced quotes, currently they fail.
  $s ~~ s:g/(<["']><.space>*)$EOS(<.space>*<.lower>)/$0$1/;

  return $s;
}

sub mark_splits(Str $request) {
  my $text = $request;
  $text ~~ s:g/(\D\d+)<termpunct>(<.space>+)/$0$<termpunct>$EOS$1/;
  $text ~~ s:g/(<.PAP><.space>)(<.space>*\()/$0$EOS$1/;
  $text ~~ s:g/(<[']><.alpha><.termpunct>)<space>/$0$EOS$<space>/;
  $text ~~ s:g:i/(<.space>'no.')(<.space>+)<!before \d>/$0$EOS$1/;

 # Add EOS when you see "a.m." or "p.m." followed by a capital letter.
 $text ~~ s:g/(<[ap]>'.m.'<.space>+)<upper>/$0$EOS$<upper>/;
  return $text;
}

sub remove_markup(@sentences) {
  for @sentences <-> $sentence {
    $sentence ~~ s:g/$ELLIPSIS/.../;
    $sentence ~~ s:g/$TWO_DOTS/. ./;
    $sentence ~~ s:g/$DOT/./; 
  }
}

sub clean_sentences(@sentences) {
  return @sentences.grep({.defined and .match(/<.alpha>/)}).map:{.trim };
}



sub show_quotes(Str $request, Str @quotes) {
  my $text = $request;
  if (@quotes.elems > 0) {
    my $quote = @quotes.shift;
    while ($text ~~ s/'XXXQUOTELESSXXX'/$quote/) {
      $quote = @quotes.shift;
    }
  }
  return $text;
}
