use v6.d;
use Test;

use P6doc;

plan 4;

my $test-docs = 't/testdata/mini-doc/test-doc'.IO;

subtest 'get-doc nonexistent elements', {
	# Nonexistent file
	my $pod-path = $test-docs.add('Type/NIKqvJAzKN4VWLggtb.pod6');
	nok get-docs($pod-path);

	# Nonexistent section
	$pod-path = $test-docs.add('Type/Str.pod6');
	nok get-docs($pod-path, :section('NIKqvJAzKN4VWLggtb'));
}

subtest 'get-doc Any', {
	my $pod-path = $test-docs.add('Type/Any.pod6');
	my $gd = get-docs($pod-path);
	
	ok $gd;
	ok $gd.contains('class Any');
}

subtest 'get-doc Any.root', {
	my $pod-path = $test-docs.add('Type/Any.pod6');
	my $gd = get-docs($pod-path, :section('root'));

	ok $gd;

	ok $gd.contains('method root');
}

# The following are independent types
# See https://github.com/perl6/doc/issues/2532
# for a related issue
subtest 'get-doc independent routine: exit', {
	my $pod-path = $test-docs.add('Type/independent-routines.pod6');

	my $gd = get-docs($pod-path, :section('exit'));

	ok $gd;

	ok $gd.contains('multi sub exit');
}
