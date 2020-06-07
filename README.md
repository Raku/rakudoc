# rakudoc [![Build Status](https://travis-ci.org/Raku/rakudoc.svg?branch=master)](https://travis-ci.org/Raku/rakudoc)

rakudoc, a tool for reading Raku documentation

```
            Usage:
                rakudoc <file>
                rakudoc [<option>...] <type>
                rakudoc [<option>...] <type>.<routine>
                rakudoc [<option>...] -r=<routine>

            Where:
                <file>                  A Raku POD file
                <type>                  A Raku type or class
                <routine>               A routine or method associated with a type

            Options:
                [-b | --build]          build a routine index
                [-d | --dir]            manually specify a doc directory
                [-h | --help]           print usage information
                [-n | --nopager]        deactivate pager usage for output

            Examples:
                rakudoc ~/my-pod-file.rakudoc
                rakudoc IO::Spec
                rakudoc Map.new
```

## Prerequisites

- Linux
- Rakudo 2019.03 (Rakudo Star **not** recommended right now)
- zef 0.7.4

## Installation

Clone the repository, the testdata is included as a submodule:

```
git clone --recurse-submodules https://github.com/Raku/rakudoc
```

If you already `git clone`'d it, you can get the submodule afterwards like this:

```
git submodule update --init --recursive
```

Then install only the remaining dependencies for `rakudoc` (note that it's
only recommended to install the dependencies for this module currently, not
the module itself, see FAQ for more information):

```
$ zef --depsonly install ./rakudoc
```

## Trying it out with the test-docs

This is the easiest way to give it a try.

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
$ RAKUDOC_TEST=1 raku -Ilib bin/rakudoc -r=new
$ RAKUDOC_TEST=1 raku -Ilib bin/rakudoc -r=abs
```

The usage of the test-data is toggled using the environment variable
`RAKUDOC_TEST`, the example sets it temporarily, this might work different
on other shells than `bash`.

### Trying it out with the full documentation

rakudoc can theoretically already be used with system installed docs in place
of the 'old' p6doc, searching for system installed documentation is the default
behaviour. However be aware that Perl6::Documentable, and through that rakudoc
require the updated POD format, as found in the current master branch of Raku/doc.

If you try it out with the currently released set of docs as they
are distributed with Rakudo Star 2019.03 for example, you might
encounter an error like the following:

```
kind not found in Path pod file config.
The first line of the pod should contain:
=begin pod :kind('<value>') :subkind('<value>') :category('<value')
```

Also there might still be problems with clashing dependency versions and
module names with Perl6::Documentable when using Rakudo Star, so it's
not recommended.

### Manually specifying a directory

To still try out `rakudoc` with the full set of documentation, it is also possible
to manually specify a directory with `-d`. First grab the
documentation from Raku/doc, for example by cloning the whole repository:

```
git clone https://github.com/Raku/doc
```

The relevant folder is the `doc` folder inside that repository (which is also
named doc).
So if you cloned both this repository, and the Raku/doc repository

```
raku-repositories/
├── doc
└── rakudoc
```

you can use it like in the following examples:

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
$ raku -Ilib bin/rakudoc -d=../doc/doc -r=say
$ raku -Ilib bin/rakudoc -d=../doc/doc -r=exit
```

## FAQ

### Why is installation of this module not yet recommended?

This project turned the former
[p6doc script from the perl6/doc repository](https://github.com/perl6/doc/blob/a38f5a5fb480aa51009e2be206c7d7d4196ac347/bin/p6doc)
into it's own module.

### Why is Rakudo Star not yet recommended?

Current and past versions of Rakudo Star ship with the complete Raku/doc documentation
repository. This project only works on the most current set of documentation files from
Raku/doc `master`. Rakudo Star may lead to wrong dependency versions being used, especially for
`Documentable`, one of this projects main dependencies. It *should* still work,
but be aware that until a new version of Rakudo Star with the most current changes
from Raku/doc is released, Rakudo Star will remain unrecommended for this project.
