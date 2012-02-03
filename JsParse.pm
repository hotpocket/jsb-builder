package JsParse;

use Node;
use strict;
use warnings;

my $debug = 1;
# recursive regex to find matching parens of Ext.define()
# so it's contents can be extracted & parsed
my $re; $re = qr/ .*?[^)]?\( (?: [^()]*  | (??{$re}) )* \) ;? /x;

#constructor 
sub new {
    my($type) = $_[0];
    my($this) = {};
    bless($this, $type);
    return($this);
}
# parses extend,requires,and uses Ext.define('newClass',{/*properties*/}
# as valid dependencies of newClass
sub defineParse {
  # $deps = hashRef != hash
  my ($str,$deps,$level) = @_;
  my @array = ($str =~ /$re/xg);
  my @matchedBlocks;
  # blocks are stuff(.*?) followed by ()
  # so Ext.define(...) is a block , so is (funtion(){})
  # nested blocks are parsed recursively
  for my $block (@array){
     if($block !~ m/Ext\.define/){ next; }
     push(@matchedBlocks, $block);
     $block =~ m/Ext\.define\(['"](.*?)['"],/;
     my $class = $1;
     my @defines  = ($block =~ m/Ext\.define/g);
     if(scalar(grep {defined $_} @defines) gt 1){ # count(@defines)
       my $tmpBlock = $block;
       $tmpBlock =~ s/Ext\.define//;
       $tmpBlock =~ s/.*?(Ext\.define)/$1/;  # includes first (
       $tmpBlock =~ s/\)$//;                 # strip last )
       my @childMatchedBlocks = defineParse($tmpBlock,$deps,$level+1);  ## Rescurse ##
       for my $cmb(@childMatchedBlocks){
           $block =~ s/\Q$cmb\E//;
       }
     }
     print "\nExt.define($level): $class " if $debug;
     # extend: 'string only'
     if($block =~ m/extend:['"](.*?)['"]/){ 
         $deps->{$class} = $deps->{$class} || {};  #class list missing, stub w/ empty hash
         my $extend = $1;
         print "\n(extends)\t-> $extend " if $debug;
         $deps->{$class}{$extend} = 1;
     }
     # requires: [list] || 'string' 
     if($block =~ m/requires:\[['"](.*?)['"]\]/ || $block =~ m/requires:['"](.*?)['"]/){
         $deps->{$class} = $deps->{$class} || {};
         my $requires = $1;
         print "\n(requires)\t-> " if $debug;
         my @reqDeps = split(/['"],['"]/,$requires);
         for my $reqDep (@reqDeps){
             $deps->{$class}{$reqDep} = 1;
             print "$reqDep\n\t\t   " if $debug;
         }
     }
     # uses: [list] || 'string'
     if($block =~ m/uses:\[['"](.*?)['"]\]/ || $block =~ m/uses:['"](.*?)['"]/){
         $deps->{$class} = $deps->{$class} || {};
         my $uses = $1; 
         print "\n(uses)\t\t-> " if $debug;
         my @useDeps = split(/['"],['"]/,$uses);
         for my $useDep (@useDeps){
             $deps->{$class}{$useDep} = 1;
             print "$useDep\n\t\t   " if $debug;
         }
     }
  }
  return @matchedBlocks;
}

# The worker method to dig data out of the js file so we know our heritage
# parsing is recursive & kicked off with a call to defineParse
sub parseClasses {
    my $this = $_[0];
    my $file = $_[1];
    print "\nparseClasses($file) called\n" if $debug;
    open(FILE, $file) or die "Can't open ".$file;
    local $/ = undef;          # flush the record seperator so we don't match against just 1 line
    my $contents = <FILE>;     # read in the whole file
    close(FILE);
    my %node; # a node is a file for the sake of building the .jsb
    $contents = strip($contents); # strip comments & whitespace
    print "\nParsing for Ext.define" if $debug;
    defineParse($contents,\%node,0); # pass by ref

   
    if($debug){
        print "\nParsed node:";
        for my $n (keys %node){
            print "\n\tclass '$n' depends on: \n";
            for my $n2 (keys %{$node{$n}}){
              print "\t\t$n2\n";
            }
        }
    }

    my $tmpNode;
    my @tmp = keys %node;
    print "\n@tmp\n---------------\n" if $debug;
    $tmpNode = new Node($file);
    for my $key (keys %node) {
        $tmpNode->addClass($key);
        for my $subkey (keys %{$node{$key}}){
            print "Adding edge: $subkey\n" if $debug;
            $tmpNode->addEdge($subkey);
        }
    }
    return $tmpNode;
}

# debug functions used by strip()
sub debugOn ($) { my ($s) = @_; print STDERR "$s\n"; }
sub debugOff ($) {}

# Strip whitespace & comments from js for easier parsing
# credit to http://code.google.com/p/jsstrip/source/browse/trunk/perl/jsstrip.pl
# Rev: 28 Oct 19, 2007
#-f --first     save first comment
#-w --white     strip white space
#-s --single    strip single line comments //
#-m --multi     strip multi line comments /* ... */
#-d --debug     Print debugging messages
sub strip ($;$;$;$;$;$) {
  my ($s, $optSaveFirst, $optWhite, $optSingle, $optMulti, $debug) = @_;
  $optSaveFirst = 0 unless(defined $optSaveFirst);
  $optWhite = 1 unless(defined $optWhite);
  $optSingle = 1 unless(defined $optSingle);
  $optMulti = 1 unless(defined $optMulti);
  $debug = \&debugOff unless(defined $debug);

  my @result = ();       # result array.  gets joined at end.
  my $i = 0;             # char index for input string
  my $j = 0;             # char forward index for input string
  my $slen = length($s); # size of input string
  my $line = 0;          # line number of file (close to it anyways)

  #
  # whitespace characters
  # 
  my $whitespace = " \n\r\t";

  #
  # items that don't need spaces next to them
  #
  my $chars = "^&|!+-*/%=?:;,{}()<>% \t\n\r\'\"[]";

  while($i < $slen) {
    # skip all "boring" characters.  This is either
    # reserved word (e.g. "for", "else", "if") or a
    # variable/object/method (e.g. "foo.color")
    $j = $i;
    while($j < $slen and index($chars, substr($s, $j, 1)) == -1) {
      $j = $j+1;
    }
    if($i != $j) {
      my $token = substr($s, $i, $j -$i);
      push(@result, $token);
      $i = $j;
    }

    if($i >= $slen) {
      # last line was unterminated with ";"
      # might want to either throw an exception
      # print a warning message
      last;
    }

    my $ch = substr($s, $i, 1);
    # multiline comments
    if($ch eq "/" and substr($s, $i+1, 1) eq "*" and substr($s, $i+2, 1) ne '@') {
      my $endC = index($s, "*/", $i+2);
      die "Found invalid /*..*/ comment" if($endC == -1);
      if(($optSaveFirst and $line == 0) or !$optMulti) {
        push(@result, substr($s, $i, $endC+2 -$i)."\n");
      }

      # count how many newlines for debuggin purposes
      $j = $i+1;
      while($j < $endC) {
        $line = $line+1 if(substr($s, $j, 1) eq "\n");
        $j = $j+1;
      }
      # keep going
      $i = $endC+2;
      next;
    }

    # singleline
    if($ch eq "/" and substr($s, $i+1, 1) eq "/") {
      my $endC = index($s, "\n", $i+2);
      my $nextC = $endC;
      if($endC == -1) {
        $endC = $slen-1;
        $nextC = $slen;
      } else {
        # rewind and remove any "\r" or trailing whitespace IN the comment
        # e.g. "//foo   " --> "//foo"
        while(index($whitespace, substr($s, $endC, 1)) != -1) {
          $endC = $endC-1;
        }
      }

      # save only if it's the VERY first thing in the file and optSaveFirst is on
      # or if we are saving all // comments
      # or if it's an MSIE conditional comment
      if(($optSaveFirst and $line == 0 and $i == 0) or !$optSingle or substr($s, $i+2, 1) eq '@') {
        push(@result, substr($s, $i, $endC+1 -$i)."\n");
      }
      $i = $nextC;
      next;
    }

    # tricky.  might be an RE
    if($ch eq "/") {
      # rewind, skip white space
      $j = 1;
      $j = $j+1 while(substr($s, $i-$j, 1) eq " ");
      &$debug("REGEXP: ".$j." backup found '".substr($s, $i-$j, 1)."'");
      if(substr($s, $i-$j, 1) eq "=" or substr($s, $i-$j, 1) eq "(") {
        # yes, this is an re
        # now move forward and find the end of it
        $j = 1;
        while(substr($s, $i+$j, 1) ne "/") {
          $j = $j+1 while(substr($s, $i+$j, 1) ne "\\" and substr($s, $i+$j, 1) ne "/");
          $j = $j+2 if(substr($s, $i+$j, 1) eq "\\");
        }
        push(@result, substr($s, $i, $i+$j+1 -$i));
        &$debug("REGEXP: ".substr($s, $i, $i+$j+1 -$i));
        $i = $i+$j+1;
        &$debug("REGEXP: now at ".$ch);
        next;
      }
    }

    # double quote strings
    if($ch eq '"') {
      $j = 1;
      while(substr($s, $i+$j, 1) ne '"') {
        $j = $j+1 while(substr($s, $i+$j, 1) ne "\\" and substr($s, $i+$j, 1) ne '"');
        $j = $j+2 if(substr($s, $i+$j, 1) eq "\\");
      }
      push(@result, substr($s, $i, $i+$j+1 -$i));
      &$debug("DQUOTE: ".substr($s, $i, $i+$j+1 -$i));
      $i = $i+$j+1;
      next;
    }

    # single quote strings
    if($ch eq "'") {
      $j = 1;
      while(substr($s, $i+$j, 1) ne "'") {
        $j = $j+1 while(substr($s, $i+$j, 1) ne "\\" and substr($s, $i+$j, 1) ne "'");
        $j = $j+2 if(substr($s, $i+$j, 1) eq "\\");
      }
      push(@result, substr($s, $i, $i+$j+1 -$i));
      &$debug("SQUOTE: ".substr($s, $i, $i+$j+1 -$i));
      $i = $i+$j+1;
      next;
    }

    # newlines
    # this is just for error and debugging output
    if($ch eq "\n" or $ch eq "\r") {
      $line = $line+1;
      &$debug("LINE: ".$line);
    }

    if($optWhite and index($whitespace, $ch) != -1) {
      # leading spaces
      if($i+1 < $slen and index($chars, substr($s, $i+1, 1)) != -1) {
        $i = $i+1;
        next;
      }
      # trailing spaces
      # if this ch is space AND the last char processed
      # is special, then skip the space
      if($#result == -1 or index($chars, substr($result[-1], -1)) != -1) {
        $i = $i+1;
        next;
      }
      # else after all of this convert the "whitespace" to
      # a single space.  It will get appended below
      $ch = " ";
    }

    push(@result, $ch);
    $i = $i+1;
  }

  # remove last space, it might have been added by mistake at the end
  if(length($result[-1]) == 1 and index($whitespace, $result[-1]) != -1) {
    pop(@result);
  }

  return join('', @result);
}

return(1); # gotta do this or it's not a package

