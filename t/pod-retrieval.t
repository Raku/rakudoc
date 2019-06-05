use v6.d;
use Test;

use lib 'lib';
use P6doc;

plan 4;

subtest "get-doc Str", {
	my $pod-path = "doc/Type/Str.pod6".IO;
	my $gd = get-docs($pod-path);
	
	nok $gd.contains('No such type');
	ok $gd.contains('class Str');
	ok $gd.contains('routine val');
	ok $gd.contains('routine chomp');
}

subtest "get-doc Str.split", {
	my $pod-path = "doc/Type/Str.pod6".IO;
	my $gd = get-docs($pod-path, :section('split'));

	nok $gd.contains('No such type');
	nok $gd.contains('class Str');

	ok $gd.contains('routine split');
	ok $gd.contains('Splits a string');
	ok $gd.contains('multi method split');
}

subtest "get-doc IO", {
	my $pod-path = "doc/Type/IO.pod6".IO;
	my $gd = get-docs($pod-path);

	nok $gd.contains('No such type');

	ok $gd.contains('role IO');
	ok $gd.contains('sub chdir');
	ok $gd.contains('sub shell');
}

subtest "get-doc IO.prompt", {
	my $pod-path = "doc/Type/IO.pod6".IO;
	my $gd = get-docs($pod-path, :section('prompt'));

	nok $gd.contains('No such type');
	nok $gd.contains('role IO');

	ok $gd.contains('multi sub prompt()');
	ok $gd.contains('multi sub prompt($msg)');
	ok $gd.contains('STDIN');
}
