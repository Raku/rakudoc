use v6.d;
use Test;

use lib 'lib';
use P6doc;
use P6doc::Index;

# Until indexing changes
use MONKEY-SEE-NO-EVAL;

plan 4;

constant INDEXDATA = EVALFILE INDEX;

subtest 'search-paths', {
	ok search-paths().join(' ').contains('/doc');
}

subtest 'module-names', {
	my $expected;

	$expected = ('Foo/Bar.pm', 'Foo/Bar.pm6', 'Foo/Bar.pod', 'Foo/Bar.pod6');
	is module-names('Foo::Bar'), $expected;

	$expected = ('Text/CSV.pm', 'Text/CSV.pm6', 'Text/CSV.pod', 'Text/CSV.pod6');
	is module-names('Text::CSV'), $expected;
}

subtest 'locate-module', {
	my Str $lm;

	$lm = locate-module('Str');
	ok $lm.contains('doc');
	ok $lm.contains('Type');
	ok $lm.contains('Str');
	ok $lm.contains('/');

	$lm = locate-module('IO');
	ok $lm.contains('doc');
	ok $lm.contains('Type');
	ok $lm.contains('IO');
	ok $lm.contains('/');
}

subtest 'disambiguate-f-search', {
	isnt disambiguate-f-search('exit', INDEXDATA), '';
	isnt disambiguate-f-search('done', INDEXDATA), '';
}
