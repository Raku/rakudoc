use v6.d;
use Test;

use Rakudoc;
use Rakudoc::Index;

###
### Remember to set env RAKUDOC_TEST to successfully run tests!
###

plan 4;

# The following is a way to test `MAIN`s from Rakudoc::CMD directly without
# triggering usage. The C<use Rakudoc::CMD> must be in a new lexical scope,
# where its MAIN will be harmlessly installed but not jumped to.
BEGIN sub MAIN(|_) { };

use IO::Capture::Simple;
my @status;
capture_stdout {
    use Rakudoc::CMD;

    @status.push: so Rakudoc::CMD::MAIN('Map', :n(True)), "Map";
    @status.push: so Rakudoc::CMD::MAIN('Map.new', :n(True)), "Map.new";
    @status.push: so Rakudoc::CMD::MAIN('X::IO', :n(True)), "X::IO";
    @status.push: so Rakudoc::CMD::MAIN('Array', :n(True)), "Array";
}

for @status -> $status, $descr { ok $status, $descr; }
