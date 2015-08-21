#!/usr/bin/env perl
use strict;
use Test::More;
use FindBin qw($Bin);
use File::Temp qw/ tempdir /;
use lib "$Bin/../lib";

use Bio::RefBuild::Util::GtfToRrnaInterval;
use autodie;

my $test_data_dir = "$Bin/data";
my $test_out_dir = tempdir( CLEANUP => 1 );

test1();
done_testing();

sub test1 {
    my $test_out_fn = "$test_out_dir/t1.rrna.interval";
    my $dict_fn     = "$test_data_dir/expected/ta1/support/ta1.fa.dict";
    my $gtf_fn      = "$test_data_dir/gencode.v22.grch38.cutdown.gtf.gz";

    open(my $in_fh,'-|', 'gzip', '-dc', $gtf_fn);
    open( my $dict_fh, '<', $dict_fn );
    open( my $out_fh,  '>', $test_out_fn );

    my $converter = Bio::RefBuild::Util::GtfToRrnaInterval->new(
        in_fh   => $in_fh,
        dict_fh => $dict_fh,
        out_fh  => $out_fh,
    );
    $converter->convert();
    map { close $_ } ( $dict_fh, $in_fh, $out_fh );

    my @test_output;
    my @expected_output;
    {
        open( my $test_result_fh, '<', $test_out_fn );
        while (<$test_result_fh>) {
            chomp;
            push @test_output, $_;
        }
        close($test_result_fh);
        while (<DATA>) {
            chomp;
            push @expected_output, $_;
        }
    }
    is_deeply( \@test_output, \@expected_output, "rRNA Interval" );
}
__DATA__
@HD	VN:1.4	SO:unsorted
@SQ	SN:chr19	LN:58617616	M5:85f9f4fc152c58cb7913c06d6b98573a	AS:ta1	UR:ftp://blahblah.fa.gz	SP:Homo sapiens
@SQ	SN:chr20	LN:64444167	M5:b18e6c531b0bd70e949a7fc20859cb01	AS:ta1	UR:ftp://blahblah.fa.gz	SP:Homo sapiens
@SQ	SN:chr21	LN:46709983	M5:974dc7aec0b755b19f031418fdedf293	AS:ta1	UR:ftp://blahblah.fa.gz	SP:Homo sapiens
@SQ	SN:chr22	LN:50818468	M5:ac37ec46683600f808cdd41eac1d55cd	AS:ta1	UR:ftp://blahblah.fa.gz	SP:Homo sapiens
chr19	453134	453245	+	ENST00000516730.1
chr19	7886977	7887096	-	ENST00000363030.1
chr19	11996809	11996916	+	ENST00000516251.1
chr19	12027913	12028021	-	ENST00000391195.1
chr19	12070164	12070271	+	ENST00000516737.1
chr19	12106497	12106614	+	ENST00000391274.1
chr19	17972025	17972117	+	ENST00000516782.1
chr19	21113128	21113236	-	ENST00000364165.1
chr19	24004358	24004507	-	ENST00000365096.1
chr19	29001670	29001775	+	ENST00000516463.1
chr19	31655356	31655461	-	ENST00000516971.1
chr19	32243965	32244083	-	ENST00000363868.1
chr19	58363438	58363562	+	ENST00000516402.1
chr20	5098387	5098476	-	ENST00000391234.1
chr20	5346006	5346160	-	ENST00000363443.1
chr20	15280764	15280873	-	ENST00000410568.1
chr20	18433842	18433944	+	ENST00000516613.1
chr20	21138956	21139074	-	ENST00000362639.1
chr20	23160857	23160971	-	ENST00000364657.1
chr20	23380896	23381012	-	ENST00000364858.1
chr20	30484925	30485076	-	ENST00000614365.1
chr20	30816156	30816274	-	ENST00000612928.1
chr20	31356870	31356978	+	ENST00000516840.1
chr20	32008351	32008472	+	ENST00000516814.1
chr20	32050588	32050705	+	ENST00000391269.1
chr20	35195306	35195423	+	ENST00000363431.1
chr20	40854119	40854229	-	ENST00000458857.1
chr20	45559758	45559876	-	ENST00000365053.1
chr20	47873191	47873273	+	ENST00000515961.1
chr20	56205052	56205173	-	ENST00000410186.1
chr21	8212572	8212724	+	ENST00000612463.1
chr21	8256781	8256933	+	ENST00000610460.1
chr21	8395607	8395759	+	ENST00000613359.1
chr21	8439823	8439975	+	ENST00000619471.1
chr21	14070871	14070986	+	ENST00000364942.1
chr21	25202207	25202315	+	ENST00000410986.2
chr21	32563075	32563210	+	ENST00000517141.1
chr21	36851911	36852028	+	ENST00000362936.1
chr21	42221173	42221286	+	ENST00000411330.1