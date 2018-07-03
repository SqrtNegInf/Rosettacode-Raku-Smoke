# Smoke testing Perl 6 Rosettacode tasks

I was at the Perl Conference when the coffee mugs were thrown and the idea of 
what was to become Perl 6 was born. Sounded great to me. I checked up on the
news about the language from time to time, being patient, knowing that Rome 2.0 
wasn't built in a day...

Time passed. 
RFC's rained from the sky.
I kept plugging away with Perl 5. 

Time passed. 
Children were born. 
I kept plugging away with Perl 5. 

Time passed. 
Hair turned gray.
I kept plugging away with Perl 5. 

Time passed. 
Empires rose and fell.
I kept plugging... (you get the idea)

## Smoking is Good (for Perl 6)

Precisely because of the very long gestation and continued evolution,
Perl 6 tasks on Rosettacode 
were really susceptible to bit-rot. I remember some guy named
[Tim](http://rosettacode.org/wiki/User:TimToady) found out 
that his own 
[Forest fire](http://rosettacode.org/wiki/Forest_fire) 
task was broken 
the day before he was jetting off to a conference
where he wanted to use it as an example.

## Timeline

Work began (though I didn't know it at the time) just before the 6.c *Christmas* release.

Daily smoke-testing results have been saved since 2016-09-01, at which point just under 600
tasks were in the system.

Now substantially complete.  

## MTYEWTKATLOP6ST
#### More than you ever want to know about the logistics of Perl 6 smoke testing

I keep track of the status of each task with custom header inserted right after
the hash-bang line:  

```
#!/usr/bin/env perl6
#u# http://rosettacode.org/wiki/Take_notes_on_the_command_line
#c# 2016-05-18 <RC
#m# MOAR: OK
#j#  JVM: OK
#p# RC prep: cp ref/take-notes.base run/take-notes.txt
#i# RC cli: "new note 1"
#f# RC file: take-notes.txt
```

URL on Rosettacode
```
#u# http://rosettacode.org/wiki/Take_notes_on_the_command_line
```

Change dates / status
```
#c# 2016-05-18 <RC
```
<RC - read from Rosettacode
>RC - written to Rosettacode
<>RC - read & written 

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
#p# RC prep: cp ref/take-notes.base run/take-notes.txt
```

command-line input
```
#i# RC cli: "new note 1"
```

When it is not practical to have a self-contained test, capture
output to a file, and test for differences:
diff ref/<fn> run/<fn>
```
#f# RC file: take-notes.txt
```

## Footer/Testing:

`$ref` - Reference output
`@res` - Results from program

Testing varies, but typically:
```
@res.join("\n"), chomp $ref;
```
