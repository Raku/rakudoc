use v6.d;

use Test;
use lib 'lib';

plan 1;

subtest 'Core', {
	use-ok("P6doc");
	use-ok("P6doc::CLI");
}

