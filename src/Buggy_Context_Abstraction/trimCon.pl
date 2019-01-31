#!/usr/bin/perl
#
use strict;
use warnings;

if (@ARGV < 2 || ! (-d $ARGV[0] || -f $ARGV[0]) || $ARGV[@ARGV-1] < 1) {
  print "Usage: trimCon.pl srcpath [dstpath] limit\n";
  print "  If srcpath is a directory, create new ./src* files from source \n";
  print "  directory files adding context before and after up to token limit.\n";
  print "  If srcpath is a file, create file at dstpath adding context before\n";
  print "  and after up to token limit.\n";
  print "  Also clip long buggy lines to limit.\n";
  print " Examples:\n";
  print "  ./trimCon.pl ../data/txt_clCon 500\n";
  print "  ./trimCon.pl ../data/txt_clCon/src-test.txt ./src-test.txt 500\n";
  exit(1);
}

# Process source files
my @files = ();
my $limit=$ARGV[@ARGV-1];
if ( -d $ARGV[0] ) {
  my $dir = $ARGV[0];
  my @filelist = <$dir/src*txt>;
  foreach my $file (@filelist) {
    push (@files,$file);
  }
} else {
  push (@files,$ARGV[0]);
}
my @linewords=();
my @filewords=();
my $maxlength=0;
foreach my $file (@files) {
  open (my $fb,'<',$file) || die "Can't open $file for reading\n";
  if (-d $ARGV[0]) {
      $file =~ s#^.*/([^/]*)$#$1#;
  } else {
      $file = $ARGV[1];
  }
  open (my $fp,'>',$file) || die "Can't open $file for writing\n";
  while (<$fb>) {
    chomp;
    my $cnt=0;
    my $pre=0;
    my $post=0;
    my $before=1;
    my $after=0;
    foreach my $w (split) {
      $cnt++;
      if (($w eq ";") || ($w eq "}")) {
        if ($before) { $pre++; }
        if ($after) { $post++; }
      } elsif ($w eq "<START_BUG>") { 
        $before = 0; 
      } elsif ($w eq "<END_BUG>") { 
        $after = 1; 
      }
    }
    while ($cnt > $limit && $pre > 0) {
      my $del="";
      my $delcnt = 0;
      if ($post * 2 > $pre) {
        if ($post == 1) {
          s/<END_BUG>\s(.*)$/<END_BUG>/ && ($del=$1);
        } else {
          s/\s([^;}]*[;}])$// && ($del=$1);
        }
      } else {
        s/^([^;}]*[;}])\s// && ($del=$1);
      }
      foreach my $w (split / /,"".$del) {
        $delcnt++;
      }
      if ($post * 2 > $pre) {
        $post--;
        $cnt -= $delcnt;
      } else {
        $pre--;
        $cnt -= $delcnt;
      }
    }
    while ($cnt > $limit) {
      s/\s\S+//;
      $cnt--;
    }
    print $fp $_,"\n"; 
  } 
  close $fb;
  close $fp;
}
