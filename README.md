# perl6-p6doc [![Build Status](https://travis-ci.org/noisegul/perl6-p6doc.svg?branch=master)](https://travis-ci.org/noisegul/perl6-p6doc)

The `p6doc` command line tool, improved!

```
            p6doc, a tool for reading perl6 documentation.

            Usage:
                p6doc <file>
                p6doc [<option>...] <type>
                p6doc [<option>...] <type>.<routine>
                p6doc [<option>...] -r=<routine>

            Where:
                <file>                  A Perl 6 POD file
                <type>                  A Perl 6 type or class
                <routine>               A routine or method associated with a type

            Options:
                [-b | --build]          build a routine index
                [-d | --dir]            manually specify a doc directory
                [-h | --help]           print usage information
                [-n | --nopager]        deactivate pager usage for output

            Examples:
                p6doc ~/my-pod-file.pod6
                p6doc IO::Spec
                p6doc Map.new
```

## Prerequisites

- Linux
- Rakudo 2019.03 (Rakudo Star **not** recommended right now)
- zef 0.7.4

## Installation

Clone the repository, the testdata is included as a submodule:

```
git clone --recurse-submodules https://github.com/noisegul/perl6-p6doc
```

If you already `git clone`'d it, you can get the submodule afterwards like this:

```
git submodule update --init --recursive
```

Until Perl6::Documentable is released and integrated into the ecosystem, manual
installation is recommended, make sure to install version `2.3.1`, if you have
a newer version, you might need to uninstall it first if there are breaking
changes:

```
zef install https://github.com/antoniogamiz/Perl6-Documentable/archive/v2.3.1.tar.gz
```

Then install only the remaining dependencies for `p6doc` (note that it's
only recommended to install the dependencies for this module currently, not
the module itself, see FAQ for more information):

```
$ zef --depsonly install ./perl6-p6doc
```

## Trying it out with the test-docs

This is the easiest way to give it a try.

From inside the repository folder, you can try out `p6doc` using the testdata,
be aware that the test-docs obviously only include the minimum, and are
primarily designed to test correct POD parsing, so they don't necessarily
represent actual documentation.

Type searching:
```
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc Map
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc Map.new
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc Array
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc Cool.abs
```

Searching for single routines:

First build the index.
```
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc -b
```

Use -r to search for a single routine:

```
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc -r=new
$ P6DOC_TEST=1 perl6 -Ilib bin/p6doc -r=abs
```

The usage of the test-data is toggled using the environment variable
`P6DOC_TEST`, the example sets it temporarily, this might work different
on other shells than `bash`.

### Trying it out with the full documentation

p6doc can theoretically already be used with system installed docs in place
of the 'old' p6doc, searching for system installed documentation is the default
behaviour. However be aware that Perl6::Documentable, and through that p6doc
require the updated POD format, as found in the current master branch of perl6/doc.

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

To still try out `p6doc` with the full set of documentation, it is also possible
to manually specify a directory with `-d`. First grab the
documentation from perl6/doc, for example by cloning the whole repository:

```
git clone https://github.com/perl6/doc
```

The relevant folder is the `doc` folder inside that repository (which is also
named doc).
So if you cloned both this repository, and the perl6/doc repository

```
perl6-repositories/
├── doc
└── perl6-p6doc
```

you can use it like in the following examples:

```
$ perl6 -Ilib bin/p6doc -d=../doc/doc IO
$ perl6 -Ilib bin/p6doc -d=../doc/doc Num
$ perl6 -Ilib bin/p6doc -d=../doc/doc Num.rand
$ perl6 -Ilib bin/p6doc -d=../doc/doc IO::Path::Unix
$ perl6 -Ilib bin/p6doc -d=../doc/doc Proc::Async.stdout
```

For routine searching, first build the index for that directory:

```
$ perl6 -Ilib bin/p6doc -d=../doc/doc -b
```

Then search for single routines in the given directory:

```
$ perl6 -Ilib bin/p6doc -d=../doc/doc -r=say
$ perl6 -Ilib bin/p6doc -d=../doc/doc -r=exit
```

## FAQ

### Why is installation of this module not yet recommended?

This project turned the former
[p6doc script from the perl6/doc repository](https://github.com/perl6/doc/blob/a38f5a5fb480aa51009e2be206c7d7d4196ac347/bin/p6doc)
into it's own module.
Both this project and the whole perl6/doc documentation project currently have
the module identity `p6doc`, same thing for some of the dependencies.

### Why is Rakudo Star not yet recommended?

Current and past versions of Rakudo Star ship with the complete perl6/doc documentation
repository. This project only works on the most current set of documentation files from
perl6/doc `master`. Rakudo Star may lead to wrong dependency versions being used, especially for
`Perl6::Documentable`, one of this projects main dependencies. It *should* still work,
but be aware that until a new version of Rakudo Star with the most current changes
from perl6/doc is released, Rakudo Star will remain unrecommended for this project.
