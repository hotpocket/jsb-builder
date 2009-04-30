#!/bin/perl

# this test was run from within eclipse and located at the project root
# e.p.i.c. perl eclipse plugin was used along w/ cygwin

$ENV{'PATH'} = "/bin:". $ENV{'PATH'};
# the following does not work.  you have to set it via the "run as" elipse dialog as an environment var for it to work
# set environment var PERL5LIB="C:\apps\cygwin\lib\perl5\5.8:C:\apps\eclipse_workspace\jsb-builder" to find strict, warnings, and JsbDepRes respectively
# or copy your perl modules to a path in @INC

## show warnings & be strict about scoping vars & stuff
use strict;
use warnings;
use JsbDepRes;

# file locations
# paths generated in the .jsb are relative to $jsbRoot
# the .jsb file should therefore always live in the jsbRoot so it references paths in the .jsb correctly
my $jsbRoot = "/cygdrive/c/apps/eclipse_workspace/jsb-builder/js/";
my $jsbFile = "$jsbRoot/test.jsb";

# rebuild the $jsbFile
print "Calculating Dependencies...\n";
my $j = new JsbDepRes($jsbRoot);
my @deps = $j->getDeps();

open(JSB, ">$jsbFile"); # open jsb file for overwrite
print "Writing .jsb:\n";
print JSB "<?xml version='1.0' encoding='utf-8'?><project path='' name='jsb-builder-test'><target name='Everything'>";

for my $dep(@deps) {
    $dep =~ s/\//\\/g; # replace / with \ for windows 
	print JSB "\n<include name='$dep'/>";
}
print JSB "\n</target></project>";
close(JSB);

print "Done.\n";