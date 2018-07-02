# Smoke testing Perl 6 Rosettacode tasks

I was at the Perl Conference when the coffee mugs were thrown and the idea of 
what was to become Perl 6 was born. Sounded great to me. I checked up on the
news of the new language from time to time, being patient knowing that Rome 2.x 
wasn't built in a day...

Time passed. 

I kept plugging away with Perl 5. 

Time passed. 
Children were born. 
I kept plugging away with Perl 5. 

Time passed. 
I kept plugging away with Perl 5. 
Empires rose and fell...

Header:
#!/usr/bin/env perl6
#u# http://rosettacode.org/wiki/Take_notes_on_the_command_line
#c# 2016-05-18 <RC
#m# MOAR: OK
#j#  JVM: OK
#p# RC prep: cp ref/take-notes.base run/take-notes.txt
#i# RC cli: "new note 1"
#f# RC file: take-notes.txt

#u#
URL on Rosettacode

#c#
Change dates / status
<RC - read from Rosettacode
>RC - written to Rosettacode
<>RC - read & written 

#m#
Status of MoarVM backend, 'OK' or 'BROKEN'

#j#
Status of JVM backend, 'OK' or 'BROKEN'

#p# RC prep:
prepare to run - mostly moving files into place

#i# RC cli:
command-line input

#f# RC file: 
When it is not practical to have a self-contained test, capture
output to a file, and test for differences:
diff ref/<fn> run/<fn>


Footer/Testing:

$ref - Reference output
@res - Results from program

Testing varies, but typically:
@res.join("\n"), chomp $ref;
