use v6.d;
use Test;

use Rakudoc;
use Rakudoc::Index;

###
### Remember to set env RAKUDOC_TEST to successfully run tests!
###

plan 4 * 2;

# The following is a way to test `MAIN`s from Rakudoc::CMD directly without
# triggering usage. The C<use Rakudoc::CMD> must be in a new lexical scope,
# where its MAIN will be harmlessly installed but not jumped to.
BEGIN sub MAIN(|_) { };

use IO::Capture::Simple;
{
    use Rakudoc::CMD;

    for
        \('Map', :n), / 'class Map' \N+ 'does Associative' /,
        \('Map.new', :n), / 'method new' /,
        \('X::IO', :n), / 'role X::IO' /,
        \('Array', :n), / 'class Array' \N+ 'is List' /
    -> $args, $like
    {
        my $result;
        my Str $out = capture_stdout {
            $result = Rakudoc::CMD::MAIN(|$args);
        };
        ok so $result, "MAIN $args.gist() reports success";
        like $out, $like, "MAIN $args.gist() output looks good";
    }
}
