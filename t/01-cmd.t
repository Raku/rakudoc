use v6.d;
use Test;

use P6doc;
use P6doc::Index;

###
### Remember to set env P6DOC_TEST to successfully run tests!
###

plan 6;

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

    ok P6doc::CMD::MAIN('');
    ok P6doc::CMD::MAIN('-h');
    ok P6doc::CMD::MAIN('Map');
    ok P6doc::CMD::MAIN('Map.new');
    ok P6doc::CMD::MAIN('X::IO');
    ok P6doc::CMD::MAIN('Array');
}

# Show test duration
my $elapsed = "Test finished after {now - INIT now} seconds";
say '-'x$elapsed.chars;
say $elapsed;
