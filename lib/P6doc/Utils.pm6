unit module P6doc::Utils;

sub findbin() returns IO::Path is export {
    $*PROGRAM.parent;
}
