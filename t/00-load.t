use v6.d;

use Test;

plan 1;

subtest 'Core', {
    use-ok('Rakudoc');
    use-ok('Rakudoc::CMD');
    use-ok('Rakudoc::Index');
    use-ok('Rakudoc::Utils');
}
