use P6doc::Utils;
use File::Find;

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

sub build_index(IO::Path $index) is export {
	my %words;

	# XXX should index more than this - currently only core pod
	# NOTE: Temporarily use the doc folder relative to the Current
	#       Working Directory $*CWD instead of using
	#       $*REPO.repo-chain() to find it, for easier testing.
	my @locations = ($*CWD>>.add: 'doc').grep: *.IO.d;
	#my @locations = ($*REPO.repo-chain()>>.Str X~ "{$*SPEC.dir-sep}doc{$*SPEC.dir-sep}").grep: *.IO.d;

	for @locations -> $lib_path is copy {
		# for p6doc -f only looking under "Type" directory is useful (and faster)
		my @files = find(:dir($lib_path.IO.add("Type")),:type('file'));

		for @files -> $f {
			my $file = $f.path;
			next if $file !~~ /\.pod6?$/;
			my $pod = substr($file.Str, 0 , $file.Str.chars -4);
			$pod.=subst($lib_path,"");
			$pod.=subst(/"{$*SPEC.dir-sep}"/,'::',:g);
			my $section = '';
			for open( $file.Str).lines -> $row {
				if $row ~~ /^\=(item|head\d) \s+ (.*?) \s*$/ {
					$section = $1.Str if $1.defined;
					%words{$section}.push([$pod, $section]) if $section ~~ m/^("method "|"sub "|"routine ")/;
				}
			}
		}
	}

	my $out = open($index, :w);
	$out.print(%words.perl);
	$out.close;
}

