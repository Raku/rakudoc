use v6.d;

use Test;

plan 2;

subtest 'Core', {
	use-ok('P6doc');
	use-ok('P6doc::CMD');
	use-ok('P6doc::Index');
	use-ok('P6doc::Utils');
}
