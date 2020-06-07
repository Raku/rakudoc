#!/usr/bin/env perl6

use v6.d;
use lib 'lib';
use Test;
BEGIN plan :skip-all<Test applicable to git checkout only> unless '.git'.IO.e;

class Test-Files {
    method files() {
        my @files;

        if @*ARGS {
            @files = @*ARGS;
        } else {
            if %*ENV<TEST_FILES> {
                @files = %*ENV<TEST_FILES>.trim.split(' ').grep(*.IO.e);
            } else {
                @files = qx<git ls-files>.lines;
            }
        }
        return @files;
    }

    method pods() {
        return $.files.grep({$_.ends-with: any(<.pod6 .rakudoc>)})
    }

    method documents() {
        return $.files.grep({$_.ends-with: any(<.pod6 .rakudoc .md>)})
    }

}

my Str @files = Test-Files.files\
.grep({$_ ne 'LICENSE'|'Makefile'})\
.grep({! $_.contains('custom-theme')})\
.grep({! $_.contains('jquery')})\
.grep({! $_.ends-with('.png')})\
.grep({! $_.ends-with('.svg')})\
.grep({! $_.ends-with('.ico')});

# Further ignore the following files
@files .= grep: not *.contains('testdata');

# Multiply plan by 2, since we test the same files for
# tabs and trailing whitespaces
plan +@files * 2;

# Test for tabs
for @files -> $file {
    my @lines;
    my $line-no = 1;
    for $file.IO.lines -> $line {
        @lines.push($line-no) if $line.contains("\t");
        $line-no++;
    }
    if @lines {
        flunk "$file has tabs on lines: {@lines}";
    } else {
        pass "$file has no tabs";
    }
}

# Test for trailing whitespaces
for @files -> $file {
    my $ok = True;
    my $row = 0;
    for $file.IO.lines -> $line {
        ++$row;
        if $line ~~ / \s $/ {
           $ok = False; last;
        }
    }
    my $error = $file;
    $error ~= " (line $row)" if !$ok;
    ok $ok, "$error: Must not have any trailing whitespace.";
}

# vim: expandtab shiftwidth=4 ft=raku
