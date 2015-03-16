#!/usr/bin/perl -w
use strict;
use warnings;
 
my $filename = $ARGV[0];
open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
 
while (my $row = <$fh>) {
  if ($row=~/^\d+\./) {
  
  chomp $row;
  my($ip,$host)=split (/ +|\t+/,$row);
 print "perl ./addHost.pl $ip\n";

  
  }
}
