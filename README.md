# rakudoc [![Build Status](https://travis-ci.org/Raku/rakudoc.svg?branch=master)](https://travis-ci.org/Raku/rakudoc)

rakudoc, a tool for reading Raku documentation

```
rakudoc, a tool for reading Raku documentation

Usage:
    rakudoc    [-n]           FILE
    rakudoc    [-n] [-d=DIR]  TYPE | FEATURE | MODULE
    rakudoc    [-n] [-d=DIR]  TYPE.ROUTINE
    rakudoc -r [-n] [-d=DIR]  ROUTINE
    rakudoc -b                build the routine index
    rakudoc -h                display this help and exit

Where:
    FILE        File containing POD documentation
    TYPE        Type or class
    MODULE      Module in Raku's module search path
    FEATURE     Raku langauge feature
    ROUTINE     Routine or method associated with a type

Options:
    [-d | --dir]            Specify a doc directory
    [-n | --nopager]        Deactivate pager usage for output

Examples:
    rakudoc ~/my-pod-file.rakumod       FILE
    rakudoc IO::Spec                    TYPE
    rakudoc JSON::Fast                  MODULE
    rakudoc exceptions                  FEATURE
    rakudoc Map.new                     TYPE.ROUTINE
    rakudoc -r starts-with              ROUTINE

See also:
    rakudoc intro
    rakudoc pod
    https://docs.raku.org/
```

## Limitations

- Does not run on Windows yet. Please report any other portability
    issues you run into.

- Windows patches are welcome!

## Installation

Clone the repository, the testdata is included as a submodule:

```
git clone --recurse-submodules https://github.com/Raku/rakudoc
```

If you already `git clone`'d it, you can get the submodule afterwards like this:

```
git submodule update --init --recursive
```

Then install dependencies:

```
$ zef --depsonly install ./rakudoc
```

## Testing against the test-docs

From inside the repository folder, you can try out `rakudoc` using the testdata,
be aware that the test-docs obviously only include the minimum, and are
primarily designed to test correct POD parsing, so they don't necessarily
represent actual documentation.

Type searching:
```
$ RAKUDOC_TEST=1 raku -Ilib bin/rakudoc Map
$ RAKUDOC_TEST=1 raku -Ilib bin/rakudoc Map.new
$ RAKUDOC_TEST=1 raku -Ilib bin/rakudoc Array
$ RAKUDOC_TEST=1 raku -Ilib bin/rakudoc Cool.abs
```

Searching for single routines:

First build the index.
```
$ RAKUDOC_TEST=1 raku -Ilib bin/rakudoc -b
```

Use -r to search for a single routine:

```
$ RAKUDOC_TEST=1 raku -Ilib bin/rakudoc -r new
$ RAKUDOC_TEST=1 raku -Ilib bin/rakudoc -r abs
```

### Trying it out with uninstalled documentation

It may be useful during development to run against an uninstalled set of
documentation which is not in Raku's module search path. Manually specify a
directory with `-d`.

Assuming you have cloned [Raku/doc](https://github.com/Raku/doc.git) and
this repository next to each other in the same folder, you can use it like
in the following examples:

```
$ raku -Ilib bin/rakudoc -d=../doc/doc IO
$ raku -Ilib bin/rakudoc -d=../doc/doc Num
$ raku -Ilib bin/rakudoc -d=../doc/doc Num.rand
$ raku -Ilib bin/rakudoc -d=../doc/doc IO::Path::Unix
$ raku -Ilib bin/rakudoc -d=../doc/doc Proc::Async.stdout
```

For routine searching, first build the index for that directory:

```
$ raku -Ilib bin/rakudoc -d=../doc/doc -b
```

Then search for single routines in the given directory:

```
$ raku -Ilib bin/rakudoc -d=../doc/doc -r say
$ raku -Ilib bin/rakudoc -d=../doc/doc -r exit
```
