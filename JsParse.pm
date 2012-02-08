# It is assumed that the javascript being parsed is valid.
# WARNING: If the javascript being parsed by this class has unmatched parens () chars it may go into an infinite loop
# this should not be the case if the js being parsed is valid

package JsParse;

use Node;
use strict;
use warnings;
use JavaScript::Minifier qw(minify);

my $debug = 0;
# recursive regex to find matching parens of Ext.define()
# so it's contents can be extracted & parsed
my $re; $re = qr/ .*?\( (?: [^()]*  | (??{$re}) )* \) ;? /x;

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
  $str =~ s/\\\\//g;
  $str =~ s/\\['"]//g;
  
  my $slen = length($str);
  my $i = 0;
  my $in = '';
  my @result = ();
  
  while($i < $slen){
    my $ch = substr($str,$i,1);
  
    # check for regex, skip quotes inside of a regex
    if($ch eq "/" and $in eq ''){
      my $lastCh = substr($str, $i-1,1);
      if($lastCh eq "=" or $lastCh eq "(") {
          # re found, strip () chars until end of re is reached
          push(@result,$ch);
          my $j = 1;
          while(substr($str, $i+$j, 1) ne "/") {
            $j = $j+1 while(substr($str, $i+$j, 1) ne "\\" and substr($str, $i+$j, 1) ne "/");
            $j = $j+2 if(substr($str, $i+$j, 1) eq "\\");
          }
          my $regex = substr($str, $i+1, $i+$j -$i);
          $regex =~ s/[()]//g;
          $i = $i+$j+1;
          push(@result,$regex);
          next;
      }
    }
    if($ch eq '"' or $ch eq "'"){
      if($in eq ''){ # start of string
        $in = $ch;
      }else{    # end of string if $ch eq $in
        if($ch eq $in){
          $in = '';
        }
      }
    }
    if($in ne '' and ($ch eq '(' or $ch eq ')')){
      #print "\nSkipping $ch at $i" if $debug;
    }else{
      push(@result,$ch);
    }
    $i++;
  }
  $str = join('',@result);

  
  print "\nExecuting recursive regex" if $debug;
  my @array = ($str =~ /$re/xg);
  my @matchedBlocks;
  # blocks are stuff(.*?) followed by ()
  # so Ext.define(...) is a block , so is (funtion(){})
  # nested blocks are parsed recursively
  my $class;
  for my $block (@array){
     if($block !~ m/Ext\.define/){ next; }
     push(@matchedBlocks, $block);
     $block =~ m/Ext\.define\(['"](.*?)['"],/;
     $class = $1;
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

my $dotCount = 0;
# The worker method to dig data out of the js file so we know our heritage
# parsing is recursive & kicked off with a call to defineParse
sub parseClasses {
    my $this = $_[0];
    my $file = $_[1];
    print ".";
    $dotCount++;
    if($dotCount % 80 eq 0){ $dotCount =0;print "\n";}
    print "\nparseClasses($file) called\n" if $debug;
    my %node; # a node is a file for the sake of building the .jsb
    open(INFILE, $file) or die "unable to open $file";
    my $contents = minify(input => *INFILE);
    close(INFILE);
    $contents =~ s/[\n\r]+//g;
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

return(1); # gotta do this or it's not a package

