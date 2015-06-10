Provide detail on requirements to run this code.

# Introduction #
I love spket as an editor but didn't want to include every Java Script file and order them (with respect to inheritance) correctly so I could get code complete in my js projects.  This is my implementation of auto building a JSB file that has the correct ordering and inclusion of new .js files.

As far as I know this should run with any version of eclipse provided a perl binary and the E.P.I.C. eclipse plugin.

## Requirements ##
### Perl ###
#### Executable ####
Your system will need to have a perl binary somewhere.  I use the perl binary that comes as part of the cygwin install but Active State or others might work(untested).  Be sure to include the path where the perl executable is located in your system path environment variable.

#### Javascript::Minify ####
This is used when parsing js files.  This CPAN module consists of a "Javascript" folder with a Minify.pm within it.  Ensure this is in one of your perl @INC paths

### Eclipse Plugins ###
[Epic home page](http://www.epic-ide.org/)

The E.P.I.C. plugin is required to run perl scripts from within eclipse.
Once this is installed and you have a perl executable on your system you are set to run perl from within eclipse.  Be sure to choose the interpreter type of cygwin from the eclipse EPIC preferences menu if you installed cygwin.


## Running the test script ##
There is a <b>testRun.pl</b> script in the root of the project.  Once all of the above is in installed and working you will be able to run it by right clicking it and click <b>Run As -> Perl Local</b>

It will generate the test.jsb3 file in the projects home folder.   To confirm it is generating this file you can delete it or modify it.

## Configuring spket ##

  1. From within eclipse <b>Window -> Preferences -> Spket -> Javascript profiles</b>.
  1. For testing purposes click the New... button and call the new profile jsb-builder (you can call yours something more specific to your project when doing it for your js project).
  1. Select the new jsb-builder item and click the "Add Library" button.
  1. Select ExtJS and click ok
  1. Select the newly created ExtJS item under jsb-builder and click the "Add File" button.
  1. Add the build/sdk.jsb3 file that comes as part of the ExtJS download
  1. Repeat step 5 and browse to the test.jsb3 generated in the "Running the test script" section.  Be sure this jsb3 file added is under the sdk.jsb3 file included on step 6 or there will be dependency issues.
  1. Close firstChild.js if it's open, right click on your eclipse project, click "Reload Javascript Profile".
  1. Open the firstChild.js in the js folder of the project
  1. Put your cursor on the `MyBase` js object that is being extended and hit F3
That's it.  This should open the base file for you.  The test.jsb3 file loaded into spket references the base.js and firstChild.js loaded in that order so dependencies are loaded in the right order.