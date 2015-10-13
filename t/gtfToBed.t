#!/usr/bin/env perl
use strict;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw/ tempdir /;
use lib "$Bin/../lib";
use File::Basename;
use Bio::RefBuild::Util::GtfToBed;
use Bio::EnsEMBL::IO::Parser::Bed;
use autodie;

my $test_data_dir = "$Bin/data";
my $test_out_dir = tempdir( CLEANUP => 1 );

my $gtf_fn = "$test_data_dir/gencode.v22.grch38.cutdown.gtf.gz";

open( my $in_fh, '-|', 'gzip', '-dc', $gtf_fn );
my $converter = Bio::RefBuild::Util::GtfToBed->new(
    in_fh                    => $in_fh,
    base_name                => 'grch38_gencode22',
    out_dir                  => $test_out_dir,
    gene_biotypes_to_convert => ['protein_coding'],
);

$converter->convert();

close($in_fh);
my @files          = glob("$test_out_dir/*");
my @file_names     = sort map { basename($_) } @files;
my @expected_files = sort qw(
  grch38_gencode22.CDS.protein_coding.bed
  grch38_gencode22.exon.protein_coding.bed
  grch38_gencode22.gene.protein_coding.bed
  grch38_gencode22.transcript.protein_coding.bed
  grch38_gencode22.UTR.protein_coding.bed
);
is_deeply( \@file_names, \@expected_files, 'Expected bed files created' );

for my $f (@files) {
    subtest basename($f) => sub {
        my $parser = Bio::EnsEMBL::IO::Parser::Bed->open($f);
        $parser->next();
        is( $parser->get_raw_chrom, 'chr19', 'region name' );
        ok( $parser->get_raw_chromStart < $parser->get_raw_chromEnd,
            'start before end' );
        ok( $parser->get_raw_name, 'has a name' );
        is( $parser->get_raw_score, '.', 'has "." for score' );
        ok( $parser->get_raw_strand, 'has a strand' );
      }
}

done_testing();
