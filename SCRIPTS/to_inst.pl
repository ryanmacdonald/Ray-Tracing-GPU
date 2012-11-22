#!/usr/bin/perl


use strict;
use warnings;


#open up the file
my $infile = $ARGV[0];

open FILE, "<$infile" or die $1;

while(<FILE>) {
  #print $_;
  if(/module\s+(\w+)/) {
    print "\t$1 $1_inst(\n\t\t.clk,\n\t\t.rst,\n";
    last;
  }
}
while(<FILE>) {
  if(/\s+(input|output).*\s+(\w+)(,\s*|\s*)\n/) {
    print "\t\t.$2$3\n";
  }
  
}
print "\t);\n\n";
