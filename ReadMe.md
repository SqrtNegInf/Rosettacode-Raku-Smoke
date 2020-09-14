# Smoke testing Raku Rosettacode tasks

This space intentionally left blank.

## Back-story

I was at The Perl Conference when the coffee mugs were thrown and the idea of 
what was to become Raku was born. Sounded great to me. I checked up on the
news about the language from time to time, being patient, knowing that Rome 2.0 
wasn't built in a day...

Time passed. 
RFC's rained from the sky.

Time passed. 
Children were born. 

Time passed. 
Hair turned gray.

Time passed. 
Empires rose and fell.

Time... (you get the idea)

The whole time I kept plugging away with Perl 5, and happy to be doing so, but with the 
dream of merging the **Perl Way** with enhancements drawn from *APL*...

But at the end of 2015 with the 6.c release looking like it really was going to happen, 
I decided to put some effort into learning the current state of Perl 6 (as it was then called) via the examples on Rosetta-Code.
And one of the first tasks I looked at was **broken**. Oh the horror! Checked the docs, saw the problem, thought:
I can fix that!  Have kept pulling the thread on that sweater for many years...

## Smoking is Good (for Raku)

Precisely because of the very long gestation and continued evolution of Raku, 
tasks on Rosetta-Code were really susceptible to bit-rot. 
For example, some guy named
[Tim](http://rosettacode.org/wiki/User:TimToady) found out 
that his very own 
[Forest fire](http://rosettacode.org/wiki/Forest_fire) 
code was broken the day before he was off to a conference
where he wanted to demonstrate it. Oops. *Someone* had to do *something*.

Daily testing results have been saved since 2016-09-01, at which point just under 600
tasks were in the system.  The task count now approaches 1200.  For each
task the `stdout` (and any `stderr`) are saved and tested against expected output 

Both MoarVM and JVM backends are being tested.  MoarVM is sync'd to `moar-blead` daily, JVM much 
less often.  Fewer tasks work with JVM.  A couple dozen crash, and it's hard to get JVM to 
work with modules (in particular, tasks that produce image output are affected by this).

Real Soon Now I will put up a pretty front-end, but for now you can view
task status report in 
[glorious mono-chrome ASCII](meta/task.txt) (very suitable for grepping).

## Timeline

Work began (though I didn't know it at the time) just before the *Christmas* release
in late 2015. A lot of tasks worked as-is, but a wide variety of small changes were needed (turns out 
debugging is a pretty good way to learn a language).   Many of the initial fixes were handling fallout 
from the GLR (**Great List Refactor**), where the 'fix' was a single `|`, but the trick was 
finding out where it was needed...

There were also Niecza-specific solutions, which were retired.

Now substantially complete, 99+% of the time tasks "just work",
aside from necessary under-the-hood upgrades like hash-key randomization.

## Tools

Using a small set of Perl 5 programs I wrote, which are [here](./bin).

Why are these written in Perl 5 not Raku?  In my defense, when I first started I didn't
know Raku that well. Plus, Raku wasn't always working 100%, so the tools might not have been
reliable.

## To-Do

Include testing of Javascript backend.

Currently testing on just macOS, expand to Linux, Windows.

## MTYEWTKATLORST
##### (more than you ever wanted to know about the logistics of Raku smoke testing)

### Header

I keep track of the status of each task with custom header inserted right after
the hash-bang line, e.g.:  

```
#!/usr/bin/env raku
#u# http://rosettacode.org/wiki/Take_notes_on_the_command_line
#c# 2016-05-18 <RC
#m# MOAR: OK
#j#  JVM: OK
#p# RC prep: cp ref/take-notes.base run/take-notes.txt
#i# RC cli: "new note 1"
#f# RC file: take-notes.txt
```

URL on Rosetta-Code
```
#u# http://rosettacode.org/wiki/Take_notes_on_the_command_line
```

Change dates / status where
* <RC - read from Rosetta-Code
* &gt;RC - written to Rosetta-Code
* <>RC - read & written 
```
#c# 2016-05-18 <RC
```

Status of MoarVM backend, 'OK' or 'BROKEN'
```
#m# OK
```

Status of JVM backend, 'OK' or 'BROKEN'
```
#j# OK
```

prepare to run - mostly moving files into place
```
#r# RC prep: cp ref/take-notes.base run/take-notes.txt
```

Meta-tag, such as 'interactive', 'graphical', 'nocode', 'trivial', 'toodamnslow', 'runs forever'
```
#t# skiptest
```

command-line input (single item)
```
#i# RC cli: "new note 1"
```

Some programs require more interaction with the user while running,
this allows multiple lines of text to be piped in
```
#=# RC pipe: 1\n2\n3
```

When it is not practical to have a self-contained test, capture
output to a file, and test for differences with
`diff ref/<fn> run/<fn>`
```
#f# RC file: take-notes.txt
```

Notes to self
```
#n# blah blah blah woof woof
```

### Footer

After downloading, I modify the task to capture program output

`@res` - results from program

`$ref` - reference output

The simplest tests then are just:
```
@res.join("\n"), chomp $ref;
```

### Random-ness

If the task involves `.rand`, `.pick`, `.roll` or any other sort of randomness, I set
a fixed seed, e.g. `srand 123456`, to get consistent output for testing. 
MoarVM and JVM differ in the random sequence they emit, 
so separate results must be tested for each.
