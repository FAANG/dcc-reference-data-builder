#!/usr/bin/env perl
use strict;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw/ tempdir /;
use lib "$Bin/../lib";

use Bio::RefBuild::Util::SplitFasta;
use IO::Uncompress::AnyUncompress qw($AnyUncompressError);
use PerlIO::gzip;
use autodie;

my $test_data_dir = "$Bin/data";
my $test_out_dir  = tempdir( CLEANUP => 1 );
my $in_fn         = "$test_data_dir/ta1.fa.gz";
my @chrs          = qw(chr19 chr20 chr21);

my @expected_contents;
{
    my $contents = file_to_array($in_fn);
    push @expected_contents, pop_seq($contents); 
    push @expected_contents, pop_seq($contents);
    push @expected_contents, $contents;    
}

test1();
test2();
done_testing();

sub test1 {

    open my $in_fh, "<:gzip", $in_fn;

    my $splitter = Bio::RefBuild::Util::SplitFasta->new(
        output_dir  => $test_out_dir,
        fasta_in_fh => $in_fh,
        gzip_output => 0
    );

    $splitter->split();

    my @files_out = glob "$test_out_dir/*.fa";
    my @expected_files = map { "$test_out_dir/$_.fa" } @chrs;
    is_deeply( \@files_out, \@expected_files, "Fasta files created" );

    check_contents(@files_out);
}

sub test2 {

    open my $in_fh, "<:gzip", $in_fn;

    my $splitter = Bio::RefBuild::Util::SplitFasta->new(
        output_dir  => $test_out_dir,
        fasta_in_fh => $in_fh,
        gzip_output => 1,
    );

    $splitter->split();

    my @files_out = glob "$test_out_dir/*.fa.gz";
    my @expected_files = map { "$test_out_dir/$_.fa.gz" } @chrs;
    is_deeply( \@files_out, \@expected_files, "Gzipped Fasta files created" );
    check_contents(@files_out);
    
}

sub check_contents {
  my @files_out = @_;
  for ( my $i = 0 ; $i < scalar(@files_out) ; $i++ ) {
    my $contents = file_to_array($files_out[$i]);
    is_deeply( $contents, $expected_contents[$i], "Fasta file contents:  $files_out[$i]" );      
  }
}

sub file_to_array {
    my ($file) = @_;

    my $opener = '<';
    if ( $file =~ /\.gz$/ ) {
        $opener .= ':gzip';
    }
    open my $fh, $opener, $file;

    my @data;
    while (<$fh>){
      push @data, $_;
    }

    close $fh;
    return \@data;
}

sub pop_seq {
  my ($contents) = @_;
  
  my $next_seq_i = -1;
  for (my $i = 1; $i < scalar(@$contents); $i++){
    if ($contents->[$i] =~ m/^>/){
      $next_seq_i = $i;
      last;
    }
  }
  my @seq = splice @$contents,0,$next_seq_i;
  return \@seq;
  
}
