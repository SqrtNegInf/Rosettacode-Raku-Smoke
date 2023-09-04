use v6;

unit module Terminal::ANSIColor;

# these will be macros one day, yet macros can't be exported so far
sub RESET         is export { "\e[0m"  }
sub BOLD          is export { "\e[1m"  }
sub UNDERLINE     is export { "\e[4m"  }
sub INVERSE       is export { "\e[7m"  }
sub BOLD_OFF      is export { "\e[22m" }
sub UNDERLINE_OFF is export { "\e[24m" }
sub INVERSE_OFF   is export { "\e[27m" }
sub ITALIC        is export { "\e[3m"  }
sub ITALIC_OFF    is export { "\e[23m"  }

my %attrs =
	reset      => "0",
	bold       => "1",
	underline  => "4",
	inverse    => "7",
	black      => "30",
	red        => "31",
	green      => "32",
	yellow     => "33",
	blue       => "34",
	magenta    => "35",
	cyan       => "36",
	white      => "37",
	default    => "39",
	on_black   => "40",
	on_red     => "41",
	on_green   => "42",
	on_yellow  => "43",
	on_blue    => "44",
	on_magenta => "45",
	on_cyan    => "46",
	on_white   => "47",
	on_default => "49";

sub color (Str $what) is export {
	my @res;
	my @a = $what.split(' ');
	for @a -> $attr {
		if %attrs{$attr}:exists {
			@res.push: %attrs{$attr}
		} elsif $attr ~~ /^ ('on_'?) (\d+ [ ',' \d+ ',' \d+ ]?) $/ {
			@res.push: ~$0 ?? '48' !! '38';
			my @nums = $1.split(',');
			die("Invalid color value $_") unless +$_ <= 255 for @nums;
			@res.push: @nums == 3 ?? '2' !! '5';
			@res.append: @nums;
		} else {
			die("Invalid attribute name '$attr'")
		}
	}
	return "\e[" ~ @res.join(';') ~ "m";
}

sub colored (Str $what, Str $how) is export {
	color($how) ~ $what ~ color('reset');
}

sub colorvalid (*@a) is export {
	for @a -> $el {
		return False unless %attrs{$el}:exists
			|| $el ~~ /^ 'on_'? (\d+ [ ',' \d+ ',' \d+ ]?) $/
				&& all($0.split(',')) <= 255;
	}
	return True;
}

sub colorstrip (*@a) is export {
	my @res;
	for @a -> $str {
		@res.push: $str.subst(/\e\[ <[0..9;]>+ m/, '', :g);
	}
	return @res.join;
}

sub uncolor (Str $what) is export {
	my @res;
	my @list = $what.comb(/\d+/);
	my %inv = %attrs.invert;
	while @list {
		my $elem = @list.shift;
		if %inv{$elem}:exists {
			@res.push: %inv{$elem}
		} elsif $elem eq '38'|'48' {
			my $type = @list.shift;
			die("Bad extended color type $type") unless $type eq '5'|'2';
			my @nums = @list.splice(0, $type eq '5' ?? 1 !! 3);
			die("Invalid color value $_") unless +$_ <= 255 for @nums;
			@res.push: ('on_' if $elem eq '48') ~ @nums.join(',')
		} else {
			die("Bad escape sequence: {'\e[' ~ $elem ~ 'm'}")
		}
	}
	return @res.join(' ');
}

=begin pod

=head1 NAME

Terminal::ANSIColor - Color screen output using ANSI escape sequences

=head1 SYNOPSIS

	use Terminal::ANSIColor;
	say color('bold'), "this is in bold", color('reset');
	say colored('what a lovely colours!', 'underline red on_green');
	say BOLD, 'good to be fat!', BOLD_OFF;
	say 'ok' if colorvalid('magenta', 'on_black', 'inverse');
	say '\e[36m is ', uncolor('\e36m');
	say colorstrip("\e[1mThis is bold\e[0m");

=head1 DESCRIPTION

Terminal::ANSIColor provides an interface for using colored output
in terminals. The following functions are available:

=head2 C<color()>

Given a string with color names, the output produced by C<color()>
sets the terminal output so the text printed after it will be colored
as specified. The following color names are recognised:

	reset bold underline inverse black red green yellow blue
	magenta cyan white default on_black on_red on_green on_yellow
	on_blue on_magenta on_cyan on_white on_default

The on_* family of colors correspond to the background colors.	One or
three numeric color values in the range 0..255 may also be specified:

	N	  # 256-color map: 8 default + 8 bright + 216 rgb cube + 24 gray
	on_N	  # Same, but background

	N,N,N	  # 24-bit r,g,b foreground color
	on_N,N,N  # 24-bit r,g,b background color

=head2 C<colored()>

C<colored()> is similar to C<color()>. It takes two Str arguments,
where the first is the string to be colored, and the second is the
(space-separated) colors to be used. The C<reset> sequence is
automagically placed after the string.

=head2 C<colorvalid()>

C<colorvalid()> gets an array of color specifications (like those
passed to C<color()>) and returns true if all of them are valid,
false otherwise.

=head2 C<colorstrip()>

C<colorstrip>, given a string, removes all the color escape sequences
in it, leaving the plain text without color effects.

=head2 C<uncolor()>

Given escape sequences, C<uncolor()> returns a string with readable
color names. E.g. passing "\e[36;44m" will result in "cyan on_blue".

=head1 Constants

C<Terminal::ANSIColor> provides constants which are just strings of
appropriate escape sequences. The following constants are available:

	RESET BOLD UNDERLINE INVERSE BOLD_OFF UNDERLINE_OFF INVERSE_OFF

=end pod

# vim: ft=perl6
