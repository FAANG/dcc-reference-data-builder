#!/usr/bin/env perl
use strict;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw/ tempdir /;
use lib "$Bin/../lib";

use Bio::RefBuild::Util::StarGenomeGenerateParams;

my $test_data_dir = "$Bin/data";
my $in_fn         = "$test_data_dir/ta1.fa.gz";

open( my $in_fh, '-|', 'gzip', '-dc', $in_fn );

my $param_calculator =
  Bio::RefBuild::Util::StarGenomeGenerateParams->new( fasta_in_fh => $in_fh, );

my $params = $param_calculator->calculate_params();

my $expected_params = {
    ref_count           => 3,
    base_count          => 169771766,
    genomeChrBinNbits   => 18,
    genomeSAindexNbases => 13,
};

is( $params->{ref_count}, $expected_params->{ref_count}, "Ref counts match" );
is( $params->{base_count}, $expected_params->{base_count}, "Base counts match" );
is( $params->{genomeChrBinNbits}, $expected_params->{genomeChrBinNbits}, "chrBinNbits match" );
is( $params->{genomeSAindexNbases}, $expected_params->{genomeSAindexNbases}, "SAindexNbases match" );


done_testing();