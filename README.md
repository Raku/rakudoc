# perl6-p6doc [![Build Status](https://travis-ci.org/noisegul/perl6-p6doc.svg?branch=master)](https://travis-ci.org/noisegul/perl6-p6doc)

The `p6doc` command line tool, improved!

## Prerequisites

- Linux, OSX
- Rakudo 2019.03
- zef 0.7.4

## Installation

`git clone --recurse-submodules https://github.com/noisegul/perl6-p6doc`

## Usage

*Note*: Things are moving and changing, so please refer to `p6doc -h`:


```
            p6doc is a tool for reading perl6 documentation.

            Options:

                [-d | --directory]      specify a doc directory
                [-h | --help]           print usage information
                [-r | --routine]        search by routine name, currently requires `-d`
                [-b | --build]          build a routine index, currently requires `-d`

            Examples:

                p6doc Map
                p6doc Map.new
                p6doc -r=abs
                p6doc -d=./large-doc/Type Map
                p6doc -d=./large-doc/Type IO::Path
                p6doc -d=./large-doc -r=split

            Note:

                Right now it is only recommended to manually specify a doc directory
```
