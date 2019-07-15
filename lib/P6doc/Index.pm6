use File::Find;
use JSON::Fast;

unit module P6doc::Index;

use P6doc::Utils;

constant $index-filename = 'p6doc-index.json';

constant @index-path-candidates = Array[IO::Path](
	("$*HOME/.perl6").IO.add($index-filename),
	$*CWD.add($index-filename)
);

sub get-index-path returns IO::Path {
	my IO::Path $index-path;

	for @index-path-candidates -> $p {
		if $p.e {
			$index-path = $p;
			last;
		}
	}

	unless $index-path.defined and $index-path.e {
		fail "Unable to find p6doc-index.json at: {@index-path-candidates.join(', ')}"
	}

	return $index-path;
}

constant INDEX is export = @index-path-candidates.first;

sub build-index(IO::Path $index) is export {
	my %words;

	for get-doc-locations() -> $lib-path {
		# for p6doc -f only looking under "Type" directory is useful (and faster)
		my @files = find(:dir($lib-path.IO.add("Type")), :type('file'));

		for @files -> $f {
			# Remove the windows only volume portion
			my $f-clean = $f.dirname.IO.add($f.basename);
			my $lib-path-clean = $lib-path.IO.dirname.IO.add($lib-path.IO.basename);

			next if $f-clean.extension !eq 'pod6';

			# Remove only the extension from the path
			my $pod = $f-clean.extension("");

			$pod .= subst($lib-path-clean, "");
			$pod .= subst(/"{$*SPEC.dir-sep}"/, '::', :g);
			my $section = '';

			for open($f).lines -> $row {
				if $row ~~ /^\=(item|head\d) \s+ (.*?) \s*$/ {
					$section = $1.Str if $1.defined;
					%words{$section}.push([$pod, $section]) if $section ~~ m/^("method "|"sub "|"routine ")/;
				}
			}
		}
	}

	spurt($index, to-json(%words));
}
