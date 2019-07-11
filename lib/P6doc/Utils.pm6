unit module P6doc::Utils;

our @sys-doc-locations = ($*REPO.repo-chain()>>.Str X~ "{$*SPEC.dir-sep}doc{$*SPEC.dir-sep}").grep: *.IO.d;
our @mini-doc-locations is export = ($*CWD>>.add: 'doc').grep: *.IO.d;

sub get-doc-locations(Bool $test = True) is export {
	if $test {
		return @mini-doc-locations
	} else {
		return @sys-doc-locations
	}
}

sub search-paths() returns Seq is export {
	#return (('.', |$*REPO.repo-chain())>>.Str X~ </doc/>).grep: *.IO.d;
	return (('.', |$*CWD)>>.Str X~ </doc/>).grep: *.IO.d
}

sub findbin() returns IO::Path is export {
	$*PROGRAM.parent;
}
