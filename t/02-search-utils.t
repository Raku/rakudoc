use v6.d;
use Test;

use P6doc;
use P6doc::Utils;
use P6doc::Index;

use JSON::Fast;

plan 5;

subtest 'check for index file', {
	if not INDEX.IO.e {
		ok build-index(INDEX), 'building index...';
	} else {
		skip 'index file already exists';
	}
}

my %index-data = from-json slurp(INDEX);

subtest 'search-paths', {
	my $d = search-paths().join(' ').contains('/doc');
	my $td = search-paths().join(' ').contains('/test-doc');
	ok ($d or $td);
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

	$lm = locate-module('Map');
	ok $lm.contains('Map');

	$lm = locate-module('Cool');
	ok $lm.contains('Cool');
}

subtest 'disambiguate-f-search', {
	skip 'sub needs to be rewritten', 2;
	#isnt disambiguate-f-search('exit', %index-data), '';
	#isnt disambiguate-f-search('done', %index-data), '';
}
