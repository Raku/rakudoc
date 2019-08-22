use v6.d;
use Test;

use P6doc;
use P6doc::Index;

###
### Remember to set env P6DOC_TEST to successfully run tests!
###

plan 4;

# The following is a way to test `MAIN`s from P6doc::CMD directly
# without triggering usage. It appears there is no straightforward
# method to suppress or capture it's output to sdtout though.
# A possible way to do that could be
# https://github.com/sergot/IO-Capture-Simple/blob/master/t/stdout.t
# But it's better to cover everything MAIN calls in other routines
# and test them instead.
BEGIN sub MAIN(|_) { };
{
    use P6doc::CMD;

    ok P6doc::CMD::MAIN('Map', :n(True));
    ok P6doc::CMD::MAIN('Map.new', :n(True));
    ok P6doc::CMD::MAIN('X::IO', :n(True));
    ok P6doc::CMD::MAIN('Array', :n(True));
}
