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
    plan 3;
    my $request = $rakudoc.request: 'File::Temp';
    my @docs = $rakudoc.search: $request;
    with @docs.first {
        isa-ok $_, Rakudoc::Doc::CompUnit,
            "Doc repr for File::Temp compunit";
        like .gist, / '/site' .* 'File::Temp' /, "Gist looks okay";
        like $rakudoc.render($_), / ^ 'NAME' \s+ 'File::Temp' /,
            "Render looks okay";
    }
    else {
        skip "Module 'File::Temp' not installed", 3;
    }
}

subtest "IO::MiddleMan" => {
    plan 3;
    my $request = $rakudoc.request: 'IO::MiddleMan';
    my @docs = $rakudoc.search: $request;
    with @docs.first {
        isa-ok $_, Rakudoc::Doc::CompUnit,
            "Doc repr for IO::MiddleMan compunit";
        like .gist, / '/site' .* 'IO::MiddleMan' /, "Gist looks okay";
        like $rakudoc.render($_), / ^ 'unit class IO::MiddleMan' /,
            "Render (raw source) looks okay";
    }
    else {
        skip "Module 'IO::MiddleMan' not installed", 3;
    }
}

# vim:ft=raku sw=4 et:
