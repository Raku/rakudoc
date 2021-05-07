use Test;
use Rakudoc;

%*ENV<RAKUDOC_TEST> = '1';
%*ENV<RAKUDOC> = 't/test-doc';

plan 2;

# Note: These two modules (File::Temp and IO::MiddleMan) are already listed
# in META6.json as test-depends, so they should typically be installed if
# this test suite is being run. But in case they are not, skip these tests
# if the modules are not found.

my $rakudoc = Rakudoc.new;

subtest "File::Temp" => {
    run-test('File::Temp', / ^ 'NAME' \s+ 'File::Temp' /);
}

subtest "IO::MiddleMan" => {
    # IO::MiddleMan does not contain any Pod documentation, so it will
    # render as the full source text
    run-test('IO::MiddleMan', / ^ 'unit class IO::MiddleMan' /);
}

sub run-test($short-name, $rendered-match) {
    plan 3;
    my $request = $rakudoc.request: $short-name;
    my @docs = $rakudoc.search: $request;
    with @docs.first {
        isa-ok $_, Rakudoc::Doc::CompUnit,
            "Doc repr for $short-name compunit";
        like .gist, / '/' .* $short-name /, "Gist looks okay";

        # Zef puts uninstalled prerequisites in ~/.zef/store/*, and the
        # Distribution object does not yield its $contents properly; it
        # renders "\n", but works fine once modules are installed
        todo "Testing not-yet-installed prerequisites unsupported"
            if .gist.contains('zef');
        like $rakudoc.render($_), $rendered-match,
            "Render looks okay";
    }
    else {
        skip "Module '$short-name' not installed", 3;
    }
}

# vim:ft=raku sw=4 et:
