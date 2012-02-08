// a javascript file that uses many things but does not extend: 'stuff' or uses: ['stuff] or requires: ['stuff]
// such a file cannot have it's deps resolved because there is no trail, but by use of ->procLast()
// this file should be included last, not first, as other "no dependencies" js files are
