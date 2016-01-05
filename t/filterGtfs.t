#!/usr/bin/env perl
use strict;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw/ tempdir /;
use lib "$Bin/../lib";
use File::Basename;
use Bio::RefBuild::Util::FilterGtfForExons;
use autodie;

use Bio::EnsEMBL::IO::Parser::GTF;

my $test_data_dir = "$Bin/data";
my $test_out_dir  = tempdir( CLEANUP => 1 );
my $test_out_fn   = "$test_data_dir/filtered.gtf";

my $expected_output_fn = "$test_data_dir/expected/very_small.exons_only.gtf";

my $gtf_fn = "$test_data_dir/very_small.gtf";

open( my $in_fh,  '<', $gtf_fn );
open( my $out_fh, '>', $test_out_fn );

my $filter = Bio::RefBuild::Util::FilterGtfForExons->new(
    in_fh  => $in_fh,
    out_fh => $out_fh
);

$filter->filter;

close $out_fh;

my $actual   = slurp_to_array($test_out_fn);
my $expected = slurp_to_array($expected_output_fn);


is_deeply( $actual, $expected, "Output contents match expected" );

done_testing();

#can't compare lines directly, attribute output order is random, so parse the GTFs 
sub slurp_to_array {
    my ($file) = @_;

    my $parser = Bio::EnsEMBL::IO::Parser::GTF->open($file);

    my @entries;
    while ( $parser->next ) {
        push @entries,
          {
            seqname => $parser->get_raw_seqname,
            source  => $parser->get_raw_source,
            type    => $parser->get_raw_type,
            start   => $parser->get_raw_start,
            end     => $parser->get_raw_end,
            score   => $parser->get_raw_score,
            strand  => $parser->get_raw_strand,
            phase   => $parser->get_raw_phase,
            attrs   => $parser->get_attributes,
          };
    }

    return \@entries;
}
