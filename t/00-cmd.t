use v6.d;
use Test;

use lib 'lib';
use P6doc;

plan 2;

# Hardcoded paths for testing only
constant TINDEX = $*PROGRAM.parent(2).add("bin{$*SPEC.dir-sep}index.data");
constant TP6DOC = $*PROGRAM.parent(2).add("bin{$*SPEC.dir-sep}p6doc");

subtest "Build index file", {
	my $p;

	$p = run($*EXECUTABLE, "bin/p6doc", "build");
	is $p.exitcode, 0;
	is TINDEX.e, True;
	is TINDEX.z, False;
}

# Note: Prepending $*EXECUTABLE ensures that this
#       works on Windows as well
subtest "Run the p6doc command", {
	my $p;

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

	$p = run($*EXECUTABLE, TP6DOC, "IO", :out, :err);
	is $p.exitcode, 0, "p6doc IO";

	# lookup Str.split
	$p = run($*EXECUTABLE, TP6DOC, "Str.split", :out, :err);
	is $p.exitcode, 0, "p6doc Str.split";
}
