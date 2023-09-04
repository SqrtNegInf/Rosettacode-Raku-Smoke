=NAME
Pod::To::Markdown - Render Pod as Markdown

=begin SYNOPSIS
From command line:

    $ perl6 --doc=Markdown lib/to/class.pm

From Perl6:
=begin code
use Pod::To::Markdown;

=NAME
foobar.pl

=SYNOPSIS
    foobar.pl <options> files ...

say pod2markdown($=pod);
=end code
=end SYNOPSIS

=begin EXPORTS
    class Pod::To::Markdown;
    sub pod2markdown; # See below
=end EXPORTS

=DESCRIPTION

unit class Pod::To::Markdown;

my Bool $in-code-block = False;

#| Render Pod as Markdown
multi sub pod2markdown(Pod::Heading $pod, Bool :$no-fenced-codeblocks) is export {
    my Str $head = pod2markdown(
	$pod.contents,
	# Collapse contents without newlines, is this correct behaviour?
	:positional-separator(' '),
	:$no-fenced-codeblocks,
    );
    head2markdown($pod.level, $head);
}

multi sub pod2markdown(Pod::Block::Code $pod, Bool :$no-fenced-codeblocks) is export {
    temp $in-code-block = True;
    if $pod.config<lang> and !$no-fenced-codeblocks {
        ("```", $pod.config<lang>, "\n", $pod.contents.join, "```").join;
    }
    else {
        $pod.contents>>.&pod2markdown(:$no-fenced-codeblocks).join.trim-trailing.indent(4);
    }
}

multi sub pod2markdown(Pod::Block::Named $pod, Bool :$no-fenced-codeblocks) is export {
    given $pod.name {
	when 'pod'    { pod2markdown($pod.contents, :$no-fenced-codeblocks) }
        when 'para'   { $pod.contents>>.&pod2markdown(:$no-fenced-codeblocks).join(' ') }
	when 'defn'   { pod2markdown($pod.contents, :$no-fenced-codeblocks) }
	when 'config' { }
	when 'nested' { }
	default       { head2markdown(1, $pod.name) ~ "\n\n" ~ pod2markdown($pod.contents, :$no-fenced-codeblocks); }
    }
}

multi sub pod2markdown(Pod::Block::Para $pod, Bool :$no-fenced-codeblocks) is export {
    $pod.contents>>.&pod2markdown(:$no-fenced-codeblocks).join
}

sub entity-escape($str) {
    $str.trans([ '&', '<', '>' ] => [ '&amp;', '&lt;', '&gt;' ])
}

multi sub pod2markdown(Pod::Block::Table $pod, Bool :$no-fenced-codeblocks) is export {
    my Str $table = '';
    $table ~= "<table>\n";
    if $pod.headers {
	$table ~= "  <thead>\n";
	$table ~= "    <tr>\n";
	for $pod.headers.item[0..*] -> $thead { # TODO: 0..* is needed, but why
	                                        #       won't it work without?
	    $table ~= "      <td>" ~ entity-escape(pod2markdown($thead, :$no-fenced-codeblocks)) ~ "</td>\n";
	}
	$table ~= "    </tr>\n";
	$table ~= "  </thead>\n";
    }
    for $pod.contents -> @cols {
	$table ~= "  <tr>\n";
	for @cols -> $td {
	    $table ~= "    <td>" ~ entity-escape(pod2markdown($td, :$no-fenced-codeblocks)) ~ "</td>\n";
	}
	$table ~= "  </tr>\n";
    }
    $table ~= "</table>";
    $table;
}

multi sub pod2markdown(Pod::Block::Declarator $pod, Bool :$no-fenced-codeblocks) {
    my $lvl = 2;
    next unless $pod.WHEREFORE.WHY;
    my $ret = '';
    my $what = do given $pod.WHEREFORE {
        when Method {
	    my $returns = ($_.signature.returns.WHICH.perl eq 'Mu')
		?? ''
		!! (' returns ' ~ $_.signature.returns.perl);
            my @params = $_.signature.params[1..*];
               @params.pop if @params[*-1].name eq '%_';
	    my $name = $_.name;
	    $ret ~= head2markdown($lvl+1, "method $name") ~ "\n\n";
	    $ret ~= "```\nmethod $name" ~ signature2markdown(@params) ~ "$returns\n```";
        }
        when Sub {
	    my $returns = ($_.signature.returns.WHICH.perl eq 'Mu')
		?? ''
		!! (' returns ' ~ $_.signature.returns.perl);
	    my @params = $_.signature.params;
	    my $name = $_.name;
	    $ret ~= head2markdown($lvl+1, "sub $name") ~ "\n\n";
	    $ret ~= "```\nsub $name" ~ signature2markdown(@params) ~ "$returns\n```";
        }
        when .HOW ~~ Metamodel::ClassHOW {
	    if ($_.WHAT.perl eq 'Attribute') {
		my $name = $_.gist.subst('!', '.');
		$ret ~= head2markdown($lvl+1, "has $name");
	    }
	    else {
		my $name = $_.perl;
		$ret ~= head2markdown($lvl, "class $name");
	    }
        }
        when .HOW ~~ Metamodel::ModuleHOW {
	    my $name = $_.perl;
	    $ret ~= head2markdown($lvl, "module $name");
        }
        when .HOW ~~ Metamodel::PackageHOW {
	    my $name = $_.perl;
	    $ret ~= head2markdown($lvl, "package $name");
        }
        default {
            ''
        }
    }
    "$what\n\n{$pod.WHEREFORE.WHY.contents}";
}

multi sub pod2markdown(Pod::Block::Comment $pod, Bool :$no-fenced-codeblocks) is export { }

multi sub pod2markdown(Pod::Item $pod, Bool :$no-fenced-codeblocks) is export {
    my $level = $pod.level // 1;
    my $markdown = '* ' ~ pod2markdown($pod.contents[0], :$no-fenced-codeblocks);
    $markdown ~= "\n\n" ~ pod2markdown($pod.contents[1..Inf], :$no-fenced-codeblocks).indent(2)
        if $pod.contents.elems > 1;
    $markdown.indent($level * 2);
}

my %formats =
  C => "bold",
  L => "underline",
  D => "underline",
  R => "inverse"
;

my %Mformats =
    U => '_',
    I => '*',
    B => '**',
    C => '`';

my %HTMLformats =
    R => 'var';

multi sub pod2markdown(Pod::FormattingCode $pod, Bool :$no-fenced-codeblocks) is export {
    return '' if $pod.type eq 'Z';
    my $text = $pod.contents>>.&pod2markdown(:$no-fenced-codeblocks).join;

    # It is safer to strip formatting in code blocks
    return $text if $in-code-block;

    if $pod.type eq 'L' {
        if $pod.meta.elems > 0 {
            $text =  '[' ~ $text ~ '](' ~ $pod.meta[0] ~ ')';
        } else {
            $text = '[' ~ $text ~ '](' ~ $text ~ ')';
        }
    }

    $text = %Mformats{$pod.type} ~ $text ~ %Mformats{$pod.type}
        if %Mformats.EXISTS-KEY: $pod.type;

    $text = sprintf '<%s>%s</%s>',
        %HTMLformats{$pod.type},
        $text,
 	%HTMLformats{$pod.type}
	if %HTMLformats.EXISTS-KEY: $pod.type;

    $text;
}

multi sub pod2markdown(Positional $pod, Str :$positional-separator = "\n\n", Bool :$no-fenced-codeblocks) is export {
    $pod>>.&pod2markdown(:$no-fenced-codeblocks).join($positional-separator)
}

multi sub pod2markdown(Pod::Config $pod, Bool :$no-fenced-codeblocks) is export { }

multi sub pod2markdown($pod, Str :$positional-separator? = "\n\n", Bool :$no-fenced-codeblocks) is export {
    $pod.Str
}

method render($pod, Bool :$no-fenced-codeblocks) {
    pod2markdown($pod, :$no-fenced-codeblocks);
}

sub head2markdown(Int $lvl, Str $head) {
    my $level = ($lvl < 6) ?? $lvl !! 6;
    given $level {
	when 1  { $head ~ "\n" ~ ('=' x $head.chars) }
	when 2  { $head ~ "\n" ~ ('-' x $head.chars) }
	default { '#' x $level ~ ' ' ~ $head }
    }
}

# sub table2markdown($pod) {
#     my @rows = $pod.contents;
#     my @maxes;
#     for @rows, $pod.headers.item -> @row {
# 	for 0..^@row -> $i {
# 	    @maxes[$i] = max @maxes[$i], @row[$i].chars;
# 	}
#     }
#     my $fmt = Arr@maxes>>.sprintf('%%-%ds)
#     @rows.map({
# 	my @cols = @_;
# 	my @ret;
# 	for 0..@_ -> $i {
# 	    @ret.push: sprintf('%-'~$i~'s',

#     if $pod.headers {
# 	@rows.unshift([$pod.headers.item>>.chars.map({'-' x $_})]);
# 	@rows.unshift($pod.headers.item);
#     }
#     @rows>>.join(' | ') ==> join("\n");
# }

sub signature2markdown($params) {
      $params.elems ??
      "(\n    " ~ $params.map({ $_.perl }).join(", \n    ") ~ "\n)"
      !! "()";
}

# vim: ts=8
