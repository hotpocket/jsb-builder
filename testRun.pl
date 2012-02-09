#!/bin/perl
# this test was run from within eclipse and located at the project root
# e.p.i.c. perl eclipse plugin was used along w/ cygwin

$ENV{'PATH'} = "/bin:". $ENV{'PATH'};
use strict;
use warnings;
# use ./*.pm over ones found in @INC
use lib ".";  
use JsbDepRes;

$| =1;  # turn off buffering so stdout actually tells us something useful on error

# file locations
# paths generated in the .jsb are relative to $jsbRoot
# the .jsb file should therefore always live in the jsbRoot so it references paths in the .jsb correctly
my $jsRoot = "/cygdrive/c/PROGRAMMER/eclipse-workspace/jsb-builder";
my $jsbFile = $jsRoot ."/test.jsb3";

# rebuild the $jsbFile
print "Calculating Dependencies...\n";
my $j = new JsbDepRes($jsRoot);
$j->addPath("js");
$j->procLast("js/main.js");
my @deps = $j->getDeps();

## Construction of the .jsb3 file is the job of this script, there is no seperate script for that
## Proceed to populate the template with our resolved dependencies

# read template
open(FILE, "<jsb3_template.txt") or die "Can't open jsb3_template.txt";
local $/ = undef;
my $template = <FILE>;
close(FILE);

# adjust spacer relative to the contents of the tempalte file
my $tab = "            ";
my $filesBlock = '"files": [{';

my @lines = ();
my ($file, $dir, $jsbLine);
for my $dep(@deps) {
    $dep =~ m/((.*)[\\\/])?(.+)/;
    ($dir,$file) =  ( $1 || '', $3 || '' );
    $jsbLine = "\n$tab    'name': '$file',\n$tab    'path': '$dir'";
    # .jsb3 files may not contain any ' chars
    $jsbLine =~ s/'/"/g;
    push(@lines, $jsbLine);
}
$filesBlock .= join("\n$tab},{",@lines);
$filesBlock .= "\n$tab}]";

$template =~ s/%%files_block%%/$filesBlock/;

open(JSB, ">$jsbFile"); # open jsb file for overwrite
print "\nWriting .jsb3:\n";
print JSB $template;
close(JSB);

print "Done.\n";