#!/usr/bin/perl
#
if (@ARGV < 1 || ! -f $ARGV[0] || ! -f "vocab.txt") {
  print "Usage: detail.pl filename\n";
  print "  Reads in the local ./vocab.txt file and reports details\n";
  print "  related to OOV tokens in each line of filename.\n";
  print " Example:\n";
  print "  ./detail.pl pass.txt\n";
  exit(1);
}

open ($fv,"<","vocab.txt") || die;
open($fp,"<",$ARGV[0]) || die;
while (<$fv>) {
  chomp; 
  $voc{$_}=1;
}
$longest=0;
while (<$fp>) {
  /^(.*)<BUG2FIX>(.*)$/ || die "BUG2FIX not found: $_";
  $l=$1;
  $fix=$2;
  $total=0;
  $lstart=0;
  $lend=0;
  $mstart=0;
  $mend=0;
  $mcount=0;
  $mparen=0;
  for (split / /,$l) {
    $tokens[$total] = $_;
    if (/<START_BUG>/) {
      $lstart=$total+1;
      $mcount=0;
      $mparen=0;
    } elsif (/<END_BUG>/) {
      $lend=$total-1;
      $mcount=0;
      $mparen=0;
    } elsif (/^\w+$/) {
      $mcount++;
    } elsif (/[()]/ && $mcount > 1) {
      $mcount++;
      $mparen++;
    } elsif ($mcount > 2 && $mparen > 0 && /,/) {
      $mcount++;
    } elsif ($mcount > 2 && $mparen == 2 && /\{/) { 
      if ($lend == 0) {
        $mstart = $total-$mcount;
      } elsif ($mend == 0) {
        $mend = $total-$mcount-1;
      }
    } else {
      $mcount=0;
      $mparen=0;
    }
    $total++;
  }
  if ($lend==0) {
    $lend=$total-1;
  }
  if ($mend==0) {
    $mend=$total-1;
  }
  $scope=0;
  $fixlen=0;
  foreach $tok (split / /,$fix) {
    $fixlen++;
    if ($voc{$tok}) {
      print "$tok: vocab\n";
    } else {
      for ($i=$lstart; $i <= $lend; $i++) {
        if ($tokens[$i] eq $tok) {
          print "$tok: inline\n";
          if ($scope < 1) { $scope = 1; }
          last;
        }
      }
      if ($i > $lend) {
        $i=1;
        while ($lstart-$i-1 >= $mstart || $lend+$i+1<= $mend) {
          if ($lstart-$i-1 >= $mstart && $tokens[$lstart-$i-1] eq $tok) {
            print "$tok: preline: $i\n";
            if ($scope < 2) { $scope = 2; }
            last;
          }
          if ($lend+$i+1 <= $mend && $tokens[$lend+$i+1] eq $tok) {
            print "$tok: postline: $i\n";
            if ($scope < 2) { $scope = 2; }
            last;
          }
          $i++;
        }
        if ($lstart-$i-1 < $mstart && $lend+$i+1 > $mend) {
          $i=1;
          while ($mstart-$i-1 >= 0 || $mend+$i+1 < $total) {
            if ($mstart-$i-1 >= 0 && $tokens[$mstart-$i-1] eq $tok) {
              print "$tok: premethod: $i\n";
              if ($scope < 3) { $scope = 3; }
              last;
            }
            if ($mend+$i+1 < $total && $tokens[$mend+$i+1] eq $tok) {
              print "$tok: postline: $i\n";
              if ($scope < 3) { $scope = 3; }
              last;
            }
            $i++;
          }
          if ($mstart-$i-1 < 0 && $mend+$i+1 >= $total) {
            print "$tok: ERROR in $fix\n";
          }
        }
      }
    }
  }
  print "fix length: $fixlen, scope: $scope\n";
  $scopes[$scope][$fixlen]++;
  if ($fixlen > $longest) {
    $longest = $fixlen;
  }
}
for ($i=0; $i <= $longest; $i++) {
  print "$i,",$scopes[0][$i]+0,",",$scopes[1][$i]+0,",",$scopes[2][$i]+0,",",$scopes[3][$i]+0,"\n";
}
