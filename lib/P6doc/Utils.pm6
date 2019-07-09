unit module P6doc::Utils;

constant @sys-doc-locations = ($*REPO.repo-chain()>>.Str X~ "{$*SPEC.dir-sep}doc{$*SPEC.dir-sep}").grep: *.IO.d;

sub search-paths() returns Seq is export {
	#return (('.', |$*REPO.repo-chain())>>.Str X~ </doc/>).grep: *.IO.d;
	return (('.', |$*CWD)>>.Str X~ </doc/>).grep: *.IO.d
}

sub findbin() returns IO::Path is export {
	$*PROGRAM.parent;
}
