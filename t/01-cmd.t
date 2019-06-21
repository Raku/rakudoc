use v6.d;
use Test;

use lib 'lib';
use P6doc;

plan 3;

# Hardcoded paths for testing only
constant TINDEX = $*PROGRAM.parent(2).add("bin{$*SPEC.dir-sep}index.data");
constant TP6DOC = $*PROGRAM.parent(2).add("bin{$*SPEC.dir-sep}p6doc");

# Note: Prepending $*EXECUTABLE ensures that this
#       works on Windows as well
subtest 'p6doc', {
	my Proc $p;
	my Str $output;

	$p = run($*EXECUTABLE, TP6DOC, :out, :err);
	is $p.exitcode, 0, 'p6doc';

	$p = run($*EXECUTABLE, TP6DOC, 'list', :out, :err);
	is $p.exitcode, 0, 'p6doc list';

	$p = run($*EXECUTABLE, TP6DOC, 'path-to-index', :out, :err);
	is $p.exitcode, 0, 'p6doc path-to-index';

	$p = run($*EXECUTABLE, TP6DOC, 'Str', :out, :err);
	is $p.exitcode, 0, 'p6doc Str';

	$p = run($*EXECUTABLE, TP6DOC, 'Str.split', :out, :err);
	is $p.exitcode, 0, 'p6doc Str.split';

	$p = run($*EXECUTABLE, TP6DOC, 'IO', :out, :err);
	is $p.exitcode, 0, 'p6doc IO';

	# See perl6/doc issue #2534
	$p = run($*EXECUTABLE, TP6DOC, 'IO::Path', :out, :err);
	$output = $p.out.slurp: :close;
	is $p.exitcode, 0, 'p6doc IO::Path';
	ok $output.contains('class IO::Path');
}

subtest 'p6doc build', {
	my Proc $p;

	if TINDEX.IO.e {
		ok unlink(TINDEX), 'Cleaning index file...';
	}

	$p = run($*EXECUTABLE, 'bin/p6doc', 'build');
	is $p.exitcode, 0, 'p6doc build';
	is TINDEX.e, True, 'index file exists';
	is TINDEX.z, False, 'index file not empty';

	my $raw-index = TINDEX.slurp;
	ok $raw-index.contains('split');
	ok $raw-index.contains('prompt');
}

subtest 'p6doc -f', {
	my Proc $p;
	my Str $output;

	# See perl6/doc issue #2532
	$p = run($*EXECUTABLE, TP6DOC, '-f', 'exit', :out, :err, :merge);
	$output = $p.out.slurp: :close;
	nok $output.contains('No documentation found'), 'p6doc -f exit';
	nok $output.contains('No such type'), 'p6doc -f exit';
	isnt $output, '';

	$p = run($*EXECUTABLE, TP6DOC, '-f', 'done', :out, :err, :merge);
	$output = $p.out.slurp: :close;
	nok $output.contains('No documentation found'), 'p6doc -f done';
	nok $output.contains('No such type'), 'p6doc -f done';
	isnt $output, '';

	$p = run($*EXECUTABLE, TP6DOC, '-f', 'prompt', :out, :err, :merge);
	$output = $p.out.slurp: :close;
	nok $output.contains('No documentation found'), 'p6doc -f prompt';
	nok $output.contains('No such type'), 'p6doc -f prompt';
	isnt $output, '';
}

# Show test duration
my $elapsed = "Test finished after {now - INIT now} seconds";
say '-'x$elapsed.chars;
say $elapsed;
