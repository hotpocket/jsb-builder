# this class parses .js files for 3 different types inherritence syntax
# 1) The jsDoc comments @class and @extends
# 2) The Ext.extend() 2 arg version  (reffered to as type 1 in this class)
# 3) The Ext.extend() 3 arg version  (reffered to as type 2 in this class)
package JsParse;

use Node;
use strict;
use warnings;

my $debug = 0;

# created soley for parsing js files to extract nodes/classes from them
# so this logic wouldn't polute the Node class 

#constructor 
sub new {
    my($type) = $_[0];
    my($this) = {};
    bless($this, $type);
    return($this);
}

# THE worker method to dig data out of the js file so we know our heritage
# extract @class, @extends, and Ext.extend lines from this js file
sub parseClasses {
    my $this = $_[0];
    my $file = $_[1];
    print "\nparseClasses($file) called" if $debug;
    open(FILE, $file) or die "Can't open ".$file;
    local $/ = undef;          # flush the record seperator so we don't match against just 1 line
    my $contents = <FILE>;     # read in the whole file
    close(FILE);
    my %node; # a node is a file for the sake of building the .jsb
    my @docComments = ($contents =~ m'(/\*\*.*?\*/)'gs);  # find doc comments
    my $class = 0;
    my $extends = 0;
    print "\nParsing doc comments" if $debug;
    for my $comment(@docComments){
        my @tags = ($comment =~ m'.*?@([\w.]+\s+[\w.]+).*'mg); # find doc tags within this comment
        for my $tag(@tags){ # $tag = 'extends Ext.Panel' or other doc tags
            if($tag =~ /extends/ || $tag =~ /class/) {  # we only care about extends & class doc tags
                my ($name, $value) = split(/\s+/,$tag);
                if($name eq "class")  { $class = $value; }
                if($name eq "extends"){ $extends = $value }
            }
        }
        # done w/ this doc comment
        if($class && $extends){
            $node{$class} = $extends;  #hashes auto filter out duplicate keys
            print "\nfound doc'd class '$class' extends '$extends'\n" if $debug;
        }
        $class=0;
        $extends=0;
    } # done parsing doc comments
    # try & parse the Ext.extend now .. to fill in the gaps where we don't have doc comments
    print "\nParsing for Ext.extend" if $debug;
    my @extExtend = ($contents =~ m'(^.*?Ext\.extend.*?$)'gm);
    for my $extended(@extExtend) {
        $extended =~ s/\s//gms;  # for some reason chomp() just wasn't doing the job
        if($extended =~ m'^\s*//' || $extended =~ m'^\s*/\*') {
            print "\nExt.extend skipped because commented '$extended'" if $debug;
            next;  # skip extend parsing if it was commented in source
        }
        print "\nExt.extend found '$extended'" if $debug; 
        my($class, $extends) = split(/=/,$extended);
        if($extends) {
            print "\nFound extend type 1 class = '$class'" if $debug;
            $extends =~ s/\s+//g; # strip whitespace
            $class =~ s/\s+//g; # strip whitespace
            $extends =~ s/Ext\.extend\(//;
            $extends =~ s/^(.*)?,.*$/$1/;
            print " extends '$extends'" if $debug;
        }else{
            print "\nFound extend type 2 " if $debug;
            $extended =~ m'.*?Ext.extend\s*\(\s*([\w\.]+)\s*,\s*([\w\.]+)\s*,?\s*([\w\.]+)?.*'m;
            $class = $1 || '';
            $extends = $2 || '';
            print "'$1' extends '$2'" if $debug;
            if($1 && $2){ # simple extend w/o object specified
                $node{$1} = $2; # $1 = class , $2 = extends
            }else{
                print "\n\nERROR PARSING: $extended\n\n";
                next;
            }
        }
        print "\nTesting node for key '$class'" if $debug;
        if(exists $node{$class}){
            if($node{$class} ne $extends){
                print "\nCONFLICT - Ext.extend '$extends' does not match doc comment '". $node{$class} ."'\n";
            }
        }else{
            $node{$class} = $extends;
        }
    }
    if($debug){
        print "\nParsed node:";
        for my $n (keys %node){
            print "\nclass '$n' extends '". $node{$n} ."'";
        }
    }
    my $tmpNode;
    my @tmp = keys %node;
    print "\n@tmp\n---------------\n" if $debug;
    $tmpNode = new Node($file);
    for my $key (keys %node) {
        $tmpNode->addClass($key);
        $tmpNode->addEdge($node{$key});
    }
    return $tmpNode;
}

return(1); # gotta do this or it's not a package

