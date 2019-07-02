use P6doc;
use P6doc::Index;

package P6doc::CLI {
	use MONKEY-SEE-NO-EVAL;

	my $PROGRAM-NAME = "p6doc";

	sub USAGE() {
		say q:to/END/;
			p6doc is a tool for reading perl6 documentation.

			Usage:

				p6doc <command> [argument]

			Commands:

				build           build an index for p6doc -f
				list            list the index keys
				path-to-index   show where the index file lives

			Examples:

				p6doc Str
				p6doc Str.split
			END
	}

	proto MAIN(|) is export {
		{*}
	}

	multi MAIN(Bool :h(:$help)?) {
		USAGE();
		exit;
	}

	multi sub MAIN('list') {
		if INDEX.IO.e {
			my %data = EVAL slurp INDEX;
			for %data.keys.sort -> $name {
				say $name
				#    my $newdoc = %data{$docee}[0][0] ~ "." ~ %data{$docee}[0][1];
				#    return MAIN($newdoc, :f);
			}
		} else {
			say "First run   $*PROGRAM-NAME build    to create the index";
			exit;
		}
	}

	multi sub MAIN('lookup', $key) {
		if INDEX.IO.e {
			my %data = EVAL slurp INDEX;
			die "not found" unless %data{$key};
			say %data{$key}.split(" ").[0];
		} else {
			say "First run   $*PROGRAM-NAME build    to create the index";
			exit;
		}
	}

	multi sub MAIN($docee, Bool :$n) {
		return MAIN($docee, :f, :$n) if defined $docee.index('.');

		put get-docs(locate-module($docee).IO, :package($docee));
	}

	multi sub MAIN($docee, Bool :$f!, Bool :$n) {

		my ($package, $method) = $docee.split('.');
		if ! $method {

			if not INDEX.IO.e {
				say "building index on first run. Please wait...";
				build_index(INDEX);
			}

			my %data = EVALFILE INDEX;

			my $final-docee = disambiguate-f-search($docee, %data);

			# NOTE: This is a temporary fix, since disambiguate-f-search
			#       does not properly handle independent routines right now.
			if $final-docee eq '' {
				$final-docee = ('independent-routines', $docee).join('.');
			}

			($package, $method) = $final-docee.split('.');

			my $m = locate-module($package);

			put get-docs($m.IO, :section($method), :$package);
		} else {
			my $m = locate-module($package);

			put get-docs($m.IO, :section($method), :$package);
		}
	}

	multi sub MAIN(Bool :$l!) {
		my @paths = search-paths() X~ <Type/ Language/>;
		my @modules;
		for @paths -> $dir {
			for dir($dir).sort -> $file {
				@modules.push: $file.basename.subst( '.'~$file.extension,'') if $file.IO.f;
			}
		}
		@modules.append: list-installed().map(*.name);
		.say for @modules.unique.sort;
	}

	multi sub MAIN(Str $file where $file.IO.e, Bool :$n) {
		put get-docs($file.IO);
	}

	# index related
	multi sub MAIN('path-to-index') {
		say INDEX if INDEX.IO.e;
	}

	multi sub MAIN('build') {
		build_index(INDEX);
	}

}
