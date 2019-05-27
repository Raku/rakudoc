use v6.d;
use Test;

plan 1;

subtest "Run the p6doc command", {
	# No arguments
	is run("bin/p6doc", :out, :err).exitcode, 0;

	# p6doc list
	is run("bin/p6doc", "list", :out, :err).exitcode, 0;

	# p6doc path-to-index
	is run("bin/p6doc", "path-to-index", :out, :err).exitcode, 0;

	# lookup Str documentation
	is run("bin/p6doc", "Str", :out, :err).exitcode, 0;

	# lookup Str.split
	is run("bin/p6doc", "Str.split", :out, :err).exitcode, 0;
}

