# recurse into a root folder provided to the constructor to find all .js files.
# the main method here is getJsFiles which starts the recursive find
package FindJs;

#constructor
sub new {
    my($type) = $_[0];
    my($this) = {};
    $this->{'root'} = $_[1];
    bless($this, $type);
    return($this);
}

# Recurse into all folders under root to find only .js files
# hard coded skipping of any content in any .svn folders
sub getJs
{
    my $this = $_[0];
    my $dirname = $_[1];

    opendir(DIR, $dirname);
    my(@names) = readdir(DIR);
    closedir(DIR);

    # Loop thru directory, handle files and directories   
    my($name);
    foreach $name (@names) {
        chomp($name);
        my($path) = "$dirname/$name";
        if( -d $path ){ # it's a folder
            if(($name ne "..") && ($name ne ".")) {
                if($path !~ /\.svn/) {   # hard code: filter out .svn folders
                $this->getJs($path);     # recurse
                }
            }
        }
        else { # it's a file
            if($path =~ /\.js$/) {  # only cache .js files for processing later
                $strip = $this->{'root'};
                $path =~ s/$strip//;    # strip all but the file part of path
                $path =~ s/^\///;       # strip off leading /
                push(@{$this->{'jsFiles'}},$path);
            }
        }
    }
    return;
}

sub getJsFiles {
    my($this) = $_[0];
    $this->getJs($this->{'root'});
    return @{$this->{'jsFiles'}};
}

return(1);           #package files must always return 1.