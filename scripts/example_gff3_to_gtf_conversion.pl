#!/usr/bin/env perl
use strict;
use warnings;
use Bio::EnsEMBL::IO::Parser::GFF3;
use autodie;
use Getopt::Long;
use Data::Dumper;
use List::Util qw(any);

my @accession_files;
my $help;

GetOptions( "accessions=s" => \@accession_files, "help" => \$help );

if ($help) {
    exec( 'perldoc', $0 );
    exit(0);
}

my %accession_lookup = get_accession_lookup(@accession_files);

my %parents;

#column order for gtf files
my @output_cols = qw(
  seqname source type start end score strand phase attributes
);

#features in type 3 that don't belong in a GTF
my @feature_types_to_skip = qw(
  match cDNA_match D_loop region
);

my $parser = Bio::EnsEMBL::IO::Parser::GFF3->open( \*STDIN );

while ( $parser->next ) {
    my %entry = (
        seqname => $parser->get_raw_seqname,
        source  => $parser->get_raw_source,
        type    => $parser->get_raw_type,
        start   => $parser->get_raw_start,
        end     => $parser->get_raw_end,
        score   => $parser->get_raw_score,
        strand  => $parser->get_raw_strand,
        phase   => $parser->get_raw_phase,
        attrs   => $parser->get_attributes,
    );

    my $id        = $entry{attrs}{ID};
    my $parent_id = $entry{attrs}{Parent};
    my $parent    = $parents{$parent_id} if ($parent_id);

    $entry{seqname} = $accession_lookup{ $entry{seqname} };

    if ($id) {
        $parents{$id} = \%entry;
    }

    # key attributes for entry may be held in parent, or under a different name
    for ( [ 'gene', 'gene_id' ], [ 'transcript', 'transcript_id' ] ) {
        my ( $src_attr, $dest_attr ) = @$_;

        #if attribute is held under a different name, copy the value
        if ( $entry{attrs}{$src_attr} && !$entry{attrs}{$dest_attr} ) {
            $entry{attrs}{$dest_attr} = $entry{attrs}{$src_attr};
        }

        #if attribute is in a parent, copy it to the child
        if ( !$entry{attrs}{$dest_attr} && $parent->{attrs}{$dest_attr} ) {
            $entry{attrs}{$dest_attr} = $parent->{attrs}{$dest_attr};
        }
    }

    if ( any { $entry{type} eq $_ } @feature_types_to_skip ) {
        next;
    }

    # create a GTF attributes line
    $entry{attributes} = join ' ', map { $_ . ' "' . $entry{attrs}{$_} . '";' }
      grep { $entry{attrs}{$_} } sort keys %{ $entry{attrs} };

    print STDOUT join( "\t", map { $_ // '' } @entry{@output_cols} ) . "\n";
}

sub get_accession_lookup {
    my @accession_files = @_;

    my %accession_lookup;

    for my $f (@accession_files) {
        open( my $fh, '<', $f );

        my @header;

        while (<$fh>) {
            chomp;
            my @vals = split /\t/;
            if (@header) {
                my %entry;
                @entry{@header} = @vals;

                my $k = $entry{'RefSeq Accession.version'};
                my ($v) =
                  grep { $_ && $_ ne 'Un' }
                  @entry{ '#Chromosome', 'GenBank Accession.version' };

                $accession_lookup{$k} = $v;
            }
            else {
                @header = @vals;
            }
        }

        close $fh;
    }

    return %accession_lookup;
}

=pod

=head1 NAME

example_gff3_to_gtf_conversion.pl

=head1 SYNOPSIS

    This script was used to convert a RefSeq GFF3 file to a GTF compatible
    with our pipeline. It is not a general purpose GFF3 to GTF converter.

=head2 OPTIONS

        -accession, path to a file listing accessions and chromosome names.
                    Can be specified multiple times.
        -help, binary flag to indicate the help should be printed


=head1 Example:

./example_gff3_to_gtf_conversion.pl -accessions chr_accessions_CHIR_1.0 -accessions unplaced_accessions_CHIR_1.0 < ref_CHIR_1.0_top_level.gff3 > ref_CHIR_1.0_top_level.converted.gtf

  This converts the GFF3 file from NCBI (currently available here at ftp://ftp.ncbi.nlm.nih.gov/genomes/Capra_hircus/GFF/ref_CHIR_1.0_top_level.gff3.gz) to GTF. It uses the accession lists from NCBI to map from accessions to names. These are available at ftp://ftp.ncbi.nlm.nih.gov/genomes/Capra_hircus/Assembled_chromosomes/chr_accessions_CHIR_1.0 and ftp://ftp.ncbi.nlm.nih.gov/genomes/Capra_hircus/Assembled_chromosomes/unplaced_accessions_CHIR_1.0 .

The columns expected in the accession files are:

#Chromosome
RefSeq Accession.version
RefSeq gi
GenBank Accession.version
GenBank gi 

'RefSeq Accession.version' is used as a key when converting the GFF sequence names, with a value of '#Chromosome' or 'GenBank Accession.version' if #Chromsoome us equal to 'Un'.
         

=cut
