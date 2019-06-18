use v6.d;

use Test;

use lib 'lib';
use P6doc;

plan 1;

# Hardcoded paths for testing only
constant TINDEX = $*PROGRAM.parent(2).add("t{$*SPEC.dir-sep}index.data");

subtest 'sub build_index', {
	if TINDEX.e {
		ok unlink(TINDEX), 'Cleaning index file...';
	}

	build_index(TINDEX);

	ok TINDEX.e, 'index file exists';
	nok TINDEX.z, 'index file is not empty';
}
