# a node requires a file at minimum to be constructed
# it has edges (dependencies) and classes within it
# this class was creted to describe a js file in the jsb generation process
package Node;

my $debug = 0;

#constructor 
sub new {
    my($type) = $_[0];
    my($this) = {};
    $this->{'name'} = $_[1];  # the file this node represents
    $this->{'edges'} = [];
    $this->{'classes'} = [];
    bless($this, $type);
    print "\nNew Node(". $this->{'name'} .")\n" if $debug;
    return($this);
}

sub getName {
    my($this) = $_[0];
    my($relative) = $_[1];
    my $name = $this->{'name'};
    if(defined $relative) {
        $name =~ s/$relative//;
    }
    return $name;
}

sub getClasses {
    my($this) = $_[0];
    my $return;
    if(!defined $this->{'classes'}){
        $return = ();
    }else{
        if(scalar($this->{'classes'}) > 1){
            print "\n". scalar($this->{'classes'}) ." classes found in getClasses" if $debug;
        }
        $return = $this->{'classes'};
    }
    print "\nreturning $return from getClasses" if $debug;
    return @{$return};
}


sub getEdges{
    my($this) = $_[0];
    # this MIGHT be useful but it's NOISY
#    if($debug){ 
#        my $numEdges = @{$this->{'edges'}};
#        my $edges = "";
#        for my $edge(@{$this->{'edges'}}) {
#            $edges .= "\n  <edge> ".  $edge;
#        }
#        print "\nreturning $numEdges from getEdges\n". $edges ." from getEdges";
#    }
    return @{$this->{'edges'}};
}

# the main worker method to dig data out of the js file so we know our heritage
sub addClass {
    my($this) = $_[0];
    my $class = $_[1];
    print "\nAdding class '$class' for". $this->shortPath() if $debug;
    push(@{$this->{'classes'}},$class); 
}

# an edge is where it touches another node , e.g. it depends on it
sub addEdge {
    my($this) = $_[0];
    my($edge) = $_[1];
    push(@{$this->{'edges'}},$edge);
    print "\nAdding edge '$edge' to '". $this->shortPath() ."'" if $debug;
    
}

# return the last folder/file part of the path stored in $this->{'name'}
sub shortPath {
    my($this) = $_[0];
    my @paths = split(/\//,$this->{'name'});
    my $len = @{@paths}-1; 
    return $paths[$len-1] ."/". $paths[$len];
}

return(1); # gotta do this or it's not a package

