use v6.d;
use Test;

use P6doc;
use P6doc::Index;

plan 3;

constant TP6DOC = $*PROGRAM.parent(2).add("bin{$*SPEC.dir-sep}p6doc");

# Note: Prepending $*EXECUTABLE ensures that this
#       works on Windows as well
subtest 'p6doc build', {
	my Proc $p;

	if INDEX.IO.e {
		ok unlink(INDEX), 'Cleaning index file...';
	}

	$p = run($*EXECUTABLE, '-Ilib', 'bin/p6doc', 'build');
	is $p.exitcode, 0, 'p6doc build';
	is INDEX.e, True, 'index file exists';
	is INDEX.z, False, 'index file not empty';

	my $raw-index = INDEX.slurp;
	ok $raw-index.contains('method new');
}

subtest 'p6doc', {
	my Proc $p;
	my Str $output;

	$p = run($*EXECUTABLE, '-Ilib', TP6DOC, :out, :err);
	is $p.exitcode, 0, 'p6doc';

	$p = run($*EXECUTABLE, '-Ilib', TP6DOC, 'list', :out, :err);
	is $p.exitcode, 0, 'p6doc list';

	$p = run($*EXECUTABLE, '-Ilib', TP6DOC, 'env', :out, :err);
	is $p.exitcode, 0, 'p6doc env';

	$p = run($*EXECUTABLE, '-Ilib', TP6DOC, 'Map', :out, :err);
	is $p.exitcode, 0, 'p6doc Map';

	$p = run($*EXECUTABLE, '-Ilib', TP6DOC, 'Map.new', :out, :err);
	is $p.exitcode, 0, 'p6doc Map.new';

	$p = run($*EXECUTABLE, '-Ilib', TP6DOC, 'Cool', :out, :err);
	is $p.exitcode, 0, 'p6doc Cool';

	# See perl6/doc issue #2534
	$p = run($*EXECUTABLE, '-Ilib', TP6DOC, 'X::IO', :out, :err);
	$output = $p.out.slurp: :close;
	is $p.exitcode, 0, 'p6doc X::IO';
	ok $output.contains('class X::IO');
}

subtest 'p6doc -f', {
	my Proc $p;
	my Str $output;

	# See perl6/doc issue #2532
	$p = run($*EXECUTABLE, '-Ilib', TP6DOC, '-f', 'exit', :out, :err, :merge);
	$output = $p.out.slurp: :close;
	nok $output.contains('No documentation found'), 'p6doc -f exit';
	nok $output.contains('No such type'), 'p6doc -f exit';
	isnt $output, '';

	$p = run($*EXECUTABLE, '-Ilib', TP6DOC, '-f', 'new', :out, :err, :merge);
	$output = $p.out.slurp: :close;
	nok $output.contains('No documentation found'), 'p6doc -f done';
	nok $output.contains('No such type'), 'p6doc -f done';
	isnt $output, '';
}

# Show test duration
my $elapsed = "Test finished after {now - INIT now} seconds";
say '-'x$elapsed.chars;
say $elapsed;
