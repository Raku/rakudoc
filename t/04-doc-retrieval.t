use Test;

use P6doc;
use Perl6::Documentable;

=begin pod

This is a test pod.

=end pod

plan 1;

my Perl6::Documentable @doclist;

skip 'Wait until the changs in Perl6::Documentable are done before writing these tests', 1;
