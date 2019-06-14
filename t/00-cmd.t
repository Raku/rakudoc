use v6.d;
use Test;

use lib 'lib';
use P6doc;

plan 3;

# Hardcoded paths for testing only
constant TINDEX = $*PROGRAM.parent(2).add("bin{$*SPEC.dir-sep}index.data");
constant TP6DOC = $*PROGRAM.parent(2).add("bin{$*SPEC.dir-sep}p6doc");

subtest "Build index file", {
	my Proc $p;

	if TINDEX.IO.e {
		say "Cleaning index file...";
		unlink TINDEX;
	}

	$p = run($*EXECUTABLE, "bin/p6doc", "build");
	is $p.exitcode, 0, "p6doc build";
	is TINDEX.e, True, "index file exists";
	is TINDEX.z, False, "index file not empty";

	my $raw-index = TINDEX.slurp;
	ok $raw-index.contains('split');
	ok $raw-index.contains('prompt');
}

# Note: Prepending $*EXECUTABLE ensures that this
#       works on Windows as well
subtest "Run the p6doc command", {
	my Proc $p;

	# No arguments
	$p = run($*EXECUTABLE, TP6DOC, :out, :err);
	is $p.exitcode, 0, "p6doc";

	# p6doc list
	$p = run($*EXECUTABLE, TP6DOC, "list", :out, :err);
	is $p.exitcode, 0, "p6doc list";

	# p6doc path-to-index
	$p = run($*EXECUTABLE, TP6DOC, "path-to-index", :out, :err);
	is $p.exitcode, 0, "p6doc path-to-index";

	# lookup Str documentation
	$p = run($*EXECUTABLE, TP6DOC, "Str", :out, :err);
	is $p.exitcode, 0, "p6doc Str";

	# lookup Str.split
	$p = run($*EXECUTABLE, TP6DOC, "Str.split", :out, :err);
	is $p.exitcode, 0, "p6doc Str.split";

	# lookup IO
	$p = run($*EXECUTABLE, TP6DOC, "IO", :out, :err);
	is $p.exitcode, 0, "p6doc IO";
}

subtest "p6doc -f", {
	my Proc $p;
	my Str $output;

	$p = run($*EXECUTABLE, TP6DOC, "-f", "exit", :out, :err, :merge);
	$output = $p.out.slurp: :close;
	nok $output.contains('No documentation found'), "p6doc -f exit";
	nok $output.contains('No such type'), "p6doc -f exit";

	$p = run($*EXECUTABLE, TP6DOC, "-f", "done", :out, :err, :merge);
	$output = $p.out.slurp: :close;
	nok $output.contains('No documentation found'), "p6doc -f done";
	nok $output.contains('No such type'), "p6doc -f done";

	$p = run($*EXECUTABLE, TP6DOC, "-f", "prompt", :out, :err, :merge);
	$output = $p.out.slurp: :close;
	nok $output.contains('No documentation found'), "p6doc -f prompt";
	nok $output.contains('No such type'), "p6doc -f prompt";
}
