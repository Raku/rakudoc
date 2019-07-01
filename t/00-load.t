use v6.d;

use Test;
use lib 'lib';

plan 2;

subtest 'Core', {
	use-ok('P6doc');
	use-ok('P6doc::CLI');
	use-ok('P6doc::Index');
	use-ok('P6doc::Utils');
}

subtest 'Pod', {
	use-ok('Pod::To::SectionFilter');
}
