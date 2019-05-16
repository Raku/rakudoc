use v6.d
use Test;

plan 1;

subtest {
	my $p = run("bin/p6doc", :out, :err);
	is $p.exitcode, 0;
}
