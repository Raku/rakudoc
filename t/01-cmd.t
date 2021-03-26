use Test;

%*ENV<RAKUDOC_TEST> = '1';

my @tests =
    \('test-no-match'), [ False, / ^ $ /, / No .* 'test-no-match' / ],
    \(:help), [ True, / ^ Usage /, / ^ $ /],
    ;

plan +@tests / 2;

# The following is a way to test `MAIN`s from Rakudoc::CMD directly without
# triggering usage. The C<use Rakudoc::CMD> must be in a new lexical scope,
# where its MAIN will be harmlessly installed but not jumped to.
BEGIN sub MAIN(|) { };

for @tests -> $args, $like {
    subtest "MAIN {$args.gist}" => {
        plan 3;
        my ($result-is, $out-like, $err-like) = @$like;

        my ($result, $out, $err) = run-test $args;

        is $result, $result-is, "returns $result-is";
        like $out, $out-like, "output like {$out-like.gist}";
        like $err, $err-like, "output like {$err-like.gist}";
    }
}

sub run-test($args) {
    use IO::MiddleMan;
    use Rakudoc::CMD;

    my $result;

    my $*USAGE = "Usage:\n  Mock USAGE for testing\n";

    my ($out, $err) = map { IO::MiddleMan.hijack: $_ }, $*OUT, $*ERR;
    try $result = Rakudoc::CMD::MAIN(|$args);
    for $err, $out { .mode = 'normal' }
    die $! if $!;

    ($result, ~$out, ~$err);
}

# vim:ft=raku sw=4 et:
