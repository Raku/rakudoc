use v6.d;
use Test;

plan 1;

# Note: Prepending $*EXECUTABLE ensures that this
#       works on Windows as well
subtest "Run the p6doc command", {
	# No arguments
	is run($*EXECUTABLE, "bin/p6doc",:out, :err).exitcode, 0;

	# p6doc list
	is run($*EXECUTABLE, "bin/p6doc", "list", :out, :err).exitcode, 0;

	# p6doc path-to-index
	is run($*EXECUTABLE, "bin/p6doc", "path-to-index", :out, :err).exitcode, 0;

	# lookup Str documentation
	is run($*EXECUTABLE, "bin/p6doc", "Str", :out, :err).exitcode, 0;

	# lookup Str.split
	is run($*EXECUTABLE, "bin/p6doc", "Str.split", :out, :err).exitcode, 0;
}
