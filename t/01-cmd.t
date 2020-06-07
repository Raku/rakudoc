use v6.d;
use Test;

use Rakudoc;
use Rakudoc::Index;

###
### Remember to set env RAKUDOC_TEST to successfully run tests!
###

plan 4;

# The following is a way to test `MAIN`s from Rakudoc::CMD directly
# without triggering usage. It appears there is no straightforward
# method to suppress or capture it's output to sdtout though.
# A possible way to do that could be
# https://github.com/sergot/IO-Capture-Simple/blob/master/t/stdout.t
# But it's better to cover everything MAIN calls in other routines
# and test them instead.
BEGIN sub MAIN(|_) { };
{
    use Rakudoc::CMD;

    ok Rakudoc::CMD::MAIN('Map', :n(True));
    ok Rakudoc::CMD::MAIN('Map.new', :n(True));
    ok Rakudoc::CMD::MAIN('X::IO', :n(True));
    ok Rakudoc::CMD::MAIN('Array', :n(True));
}
