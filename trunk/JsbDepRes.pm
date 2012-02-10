# this class requires a root instance variable to parse & resolve dependencies from
# js files are found using the JsParse package/class, stored as nodes, and recursively evaluated for their dependencies.
# Any dependencies not found under the "root" are assumed to be already loaded prior to this process (a.k.a. outside the scope of this class)
# and thus marked as resolved
package JsbDepRes;

$ENV{'PATH'} = "/bin:". $ENV{'PATH'};
use strict;
use warnings;

# include our packages (classes)
use FindJs;
use Node;
use JsParse;

my $debug = 0;

sub new {
    my($type) = $_[0];
    my($this) = {};
    my $root = $_[1];
    # some vars to keep track of what is already loaded
    $root =~ s/\/+$//g;
    $this->{'root'} = $root;
    $this->{'paths'} = ();
    $this->{'procLast'} = {};
    $this->{'cirCheck'} = {};  # stores classes names that are in the processing of being resolved to avoid circular reference issues
    $this->{'classNodeMap'} = {};
    $this->{'depOrder'} = []; 
    bless($this, $type);
    return($this);   
}

sub procLast {
    my $this = $_[0];
    my $path = $_[1];
    $this->{'procLast'}{$path} = 1;
}

sub addPath {
    my $this = $_[0];
    my $path = $_[1];
    push(@{$this->{'paths'}},$path);
}

sub getDeps {
    my $this = $_[0];
    my @nodes;
    my $node;
    
    my @jsFiles = ();
    my $findJs;
    # create class objects
    for my $path(@{$this->{'paths'}}){
        $findJs = new FindJs($this->{'root'}."/$path");
        for my $jsFile($findJs->getJsFiles()){
            push(@jsFiles,"$path/$jsFile");
        }
    }

    my $jsParse = new JsParse();
    print "\nReading js files " if $debug;
    for my $jsFile (@jsFiles) {
        print "." if $debug;
        if($node = $jsParse->parseClasses($this->{'root'}."/$jsFile")) {
            print "+" if $debug;
            push(@nodes,$node);
        };
    }
    
    for my $node (@nodes){
        print "\nProcessing node ". $node->shortPath() if $debug;
        for my $class($node->getClasses()) {
            print "\n  <class> ". $class if $debug; 
            $this->{'classNodeMap'}{$class}{'node'} = $node;
            $this->{'classNodeMap'}{$class}{'loaded'} =  0;
        }
        for my $edge($node->getEdges()) {
            print "\n  <edge> ".  $edge if $debug;
        }
    }
    
    for my $item (keys %{$this->{'classNodeMap'}}){
        print "\nResolvingDep $item <in> ". $this->{'classNodeMap'}{$item}{node}->shortPath() if $debug;
        $this->loadDep($item);
    }
    
    if($debug) {
        print "\nLoad order is: ";
        for my $d (@{$this->{'depOrder'}}){
            print "\n$d";
        }
    }
    
    for my $n (@nodes){
        if(scalar($n->getClasses()) == 0){ # no classes defined for this
            print "\n". $n->getName() ." Contains no classes or deps" if $debug;
            unshift(@{$this->{'depOrder'}},$n->getName($this->{'root'}));  # put the items in the beginning of the array, not the end (push)
        }
    }
    
    # remove all but the first occurance of a dependency so its not loaded multiple times
    # once it's resolved, it should not be loaded again for others that reference it
    my @uniqDep;
    my %uniq;
    for my $dep(@{$this->{'depOrder'}}) {
        if(defined $uniq{$dep}){ next; }
        if(defined $this->{'procLast'}{$dep}){
            $this->{'procLast'}{$dep} = 2;
            next;
        }
        push(@uniqDep,$dep);
        $uniq{$dep} = 1;
    }
    for my $tail(keys %{$this->{'procLast'}}){
        if($this->{'procLast'}{$tail} == 2){
            print "\nLast Processing: $tail\n" if $debug;
            push(@uniqDep,$tail);
        }
    }
    return @uniqDep;
    #return @{$this->{'depOrder'}};
}

sub loadDep {
    my $this = $_[0];
    my $class = $_[1];
    if(!defined $this->{'classNodeMap'}{$class} || !defined $this->{'classNodeMap'}{$class}{'node'}) { # dep not in our lib, assume loaded
        return;
    }
    my $node = $this->{'classNodeMap'}{$class}{'node'};
    for my $dep($node->getEdges()) {
        if(!defined $this->{'classNodeMap'}{$dep} || 
           !defined $this->{'classNodeMap'}{$dep}{'node'} || 
           $this->{'classNodeMap'}{$dep}{'loaded'})
        {  # return if already loaded
            if($debug){
                my $why;
                if(!defined $this->{'classNodeMap'}{$dep}){ 
                    $why = "Dependency $dep not ours to load, assumed loaded\n";}
                if(!defined $this->{'classNodeMap'}{$dep}{'node'}){
                    $why .= "Missing file node for $dep\n";}
                if($this->{'classNodeMap'}{$dep}{'loaded'}){
                    $why .= "|classNoceMap{dep}{loaded} = 1\n";}
                print "\nSkipping $dep, already loaded\n$why";
            }
            next;
        }
        print "\nProcessing edge $dep" if $debug;
        # skip further processing of "circular references" because they just might be a file that references itself for dependencies
        # and if not, we can't resolve it anyway.
        if(defined $this->{'cirCheck'}{$dep}){ next; } # skip further processing circular references
        $this->{'cirCheck'}{$dep} = $class;
        if($this->{'classNodeMap'}{$dep}{loaded}){ next; }
        no warnings 'recursion'; # there may be lots and lots of dependencies to resolve...
        $this->loadDep($dep);
        $this->{'cirCheck'}{$dep} = undef;        #dep loaded, remove it from cirCheck
        if(defined $this->{'classNodeMap'}{$dep} && !$this->{'classNodeMap'}{$dep}{loaded}) {  # dep in our lib, & all it's deps resolved
             $this->{'classNodeMap'}{$dep}{loaded} = 1;
             print "\nLoading $dep" if $debug;
             push(@{$this->{'depOrder'}}, $this->{'classNodeMap'}{$dep}{node}->getName($this->{'root'}));
        }
        # if resolving this dep caused a file to get loaded that contains another class, mark that class as loaded too
    }
    if(defined $this->{'classNodeMap'}{$class} && !$this->{'classNodeMap'}{$class}{loaded}) {  # dep in our lib, & all it's deps resolved
         $this->{'classNodeMap'}{$class}{loaded} = 1;
         print "\nLoading $class" if $debug;
         push(@{$this->{'depOrder'}}, $this->{'classNodeMap'}{$class}{node}->getName($this->{'root'}));
    }
    # class loaded, remove it from cirCheck
    $this->{'cirCheck'}{$class} = undef;
}

return(1);