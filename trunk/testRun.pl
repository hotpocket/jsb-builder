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

open(JSB, ">$jsbFile"); # open jsb file for overwrite
print "\nWriting .jsb3:\n";
my $jsbLine = "{\n  'projectName': 'jsb3 includes', \n  'builds': ".
           "[{\n    'target': 'test_all.js',\n    'name': 'Everything',\n    'compress': true, \n    'files': ".
           "[{\n      ";
           
$jsbLine =~ s/'/"/g; # aparently it's invalid to use single quotes in a jsb3
print JSB $jsbLine;

my @lines = ();
my $file = '';
my $dir = '';
for my $dep(@deps) {
    $dep =~ m/((.*)[\\\/])?(.+)/;
    ($dir,$file) =  ( $1 || '', $3 || '' );
    my $jsbLine = "  'name': '$file',\n        'path': '$dir'";
    $jsbLine =~ s/'/"/g;
    push(@lines, $jsbLine);
}
my $data = join("\n      },{\n      ",@lines);
print JSB "$data\n    }]\n  }],\n}";
close(JSB);

print "Done.\n";