use v6.d;

use Test;

use P6doc;
use P6doc::Index;

plan 1;

subtest 'sub build_index', {
	if INDEX.e {
		ok unlink(INDEX), 'Cleaning index file...';
	}

	build_index(INDEX);

	ok INDEX.e, 'index file exists';
	nok INDEX.z, 'index file is not empty';
}
