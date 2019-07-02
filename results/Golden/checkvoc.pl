#!/usr/bin/perl
#
if (@ARGV < 1 || ! -f $ARGV[0] || ! -f "vocab.txt") {
  print "Usage: checkvoc.pl filename\n";
  print "  Reads in the local ./vocab.txt file and reports the number of words\n";
  print "  in or out of the vocab for each line of filename.\n";
  print " Example:\n";
  print "  ./checkvoc.pl pass.txt\n";
  exit(1);
}

open ($fv,"<","vocab.txt") || die;
open($fp,"<",$ARGV[0]) || die;
while (<$fv>) {
  chomp; 
  $voc{$_}=1;
}
while (<$fp>) {
  /^(.*)<BUG2FIX>(.*)$/ || die "Can't find BUG2FIX";
  $l=$2;
  $tot=0;
  $out=0;
  for (split / /,$l) {
    $tot++;
    if (!$voc{$_}) {
      $out++;
    }
  }
  if ($max[$tot] <= $out) {
    $max[$tot] = $out;
  }
  $cnt[$tot]+=$tot;
  $sum[$tot]+=$out;
  if ($tot > $longest) {
    $longest=$tot;
  }
}
for ($i=0; $i <= $longest; $i++) {
  if ($cnt[$i]) {
    print "$i, $max[$i], ",$sum[$i]/$cnt[$i],"\n";
  } else {
    print "$i, 0, ",0,"\n";
  }
}
