use P6doc::Utils;

unit module P6doc::Index;

constant INDEX is export = findbin().add('index.data');

sub get-index-path {
	my IO::Path $index-path;

	my @path-candidates = (
		("$*HOME/.perl6").IO.add('p6doc-index.data'),
	);
	for @path-candidates -> $path {
		if $path.e {
			$index-path = $path;
			last;
		}
	}

	unless $index-path.defined and $index-path.e {
		fail "Unable to find p6doc-index.data at: {@path-candidates.join(', ')}"
	}

	return $index-path;
}
