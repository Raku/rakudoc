use v6.d;
use Test;

use lib 'lib';
use P6doc;

plan 6;

subtest 'get-doc Str', {
	my $pod-path = 'doc/Type/Str.pod6'.IO;
	my $gd = get-docs($pod-path);
	
	nok $gd.contains('No such type');
	ok $gd.contains('class Str');
	ok $gd.contains('routine val');
	ok $gd.contains('routine chomp');
}

subtest 'get-doc Str.split', {
	my $pod-path = 'doc/Type/Str.pod6'.IO;
	my $gd = get-docs($pod-path, :section('split'));

	nok $gd.contains('No such type');
	nok $gd.contains('class Str');

	ok $gd.contains('routine split');
	ok $gd.contains('Splits a string');
	ok $gd.contains('multi method split');
}

subtest 'get-doc IO', {
	my $pod-path = 'doc/Type/IO.pod6'.IO;
	my $gd = get-docs($pod-path);

	nok $gd.contains('No such type');

	ok $gd.contains('role IO');
	ok $gd.contains('sub chdir');
	ok $gd.contains('sub shell');
}

subtest 'get-doc IO.prompt', {
	my $pod-path = 'doc/Type/IO.pod6'.IO;
	my $gd = get-docs($pod-path, :section('prompt'));

	nok $gd.contains('No such type');
	nok $gd.contains('role IO');

	ok $gd.contains('multi sub prompt()');
	ok $gd.contains('multi sub prompt($msg)');
	ok $gd.contains('STDIN');
}

# The following are independent types
# See https://github.com/perl6/doc/issues/2532
# for a related issue
subtest 'get-doc independent routine: exit', {
	my $pod-path = 'doc/Type/independent-routines.pod6'.IO;
	my $gd = get-docs($pod-path, :section('exit'));

	nok $gd.contains('No documentation found');
	nok $gd.contains('No such type');

	ok $gd.contains('multi sub exit');
	ok $gd.contains('LEAVE');
	ok $gd.contains('&*EXIT');
}

subtest 'get-doc independent routine: done', {
	my $pod-path = 'doc/Type/independent-routines.pod6'.IO;
	my $gd = get-docs($pod-path, :section('done'));

	nok $gd.contains('No documentation found');
	nok $gd.contains('No such type');

	ok $gd.contains('sub done(--> Nil)');
	ok $gd.contains('done;');
}
