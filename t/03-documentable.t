use Test;
use Rakudoc;

%*ENV<RAKUDOC_TEST> = '1';
%*ENV<RAKUDOC> = 't/testdata/mini-doc/test-doc';

plan 2;

my $rakudoc = Rakudoc.new;

subtest "language" => {
    plan 3;
    my $doc = Doc::Documentable.new: :$rakudoc,
                :origin(%*ENV<RAKUDOC>.IO
                    .add('Language')
                    .add('operators.pod6'));
    isa-ok $doc, Rakudoc::Doc::Documentable, "Doc repr for Language/operators";
    like $doc.gist, rx/operators/, "Gist looks okay";
    like $rakudoc.render($doc), rx/Operators/, "Render looks okay";
}

subtest "type" => {
    plan 1;
    my $doc = Doc::Documentable.new: :$rakudoc,
                :origin(%*ENV<RAKUDOC>.IO
                    .add('Type')
                    .add('Any.pod6'));
    like $rakudoc.render($doc), rx:s/class Any/,
        "Render looks okay";
}

# vim:ft=raku sw=4 et:
