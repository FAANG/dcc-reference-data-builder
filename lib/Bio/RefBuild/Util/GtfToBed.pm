package Bio::RefBuild::Util::GtfToBed;

use strict;
use namespace::autoclean;
use Moose;
use Bio::EnsEMBL::IO::Parser::GTF;
use Moose::Util::TypeConstraints;

subtype 'BedColCount', as 'Int', where { ( $_ >= 3 && $_ <= 6 ) },
  message { "$_ must be between 3 and 6 integer!" };

no Moose::Util::TypeConstraints;

has 'in_fh'   => ( is => 'rw', isa => 'FileHandle', required => 1 );
has 'out_dir' => ( is => 'rw', isa => 'Str',        required => 1 );
has 'preferred_name_keys' => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    default  => sub { [qw(exon_id transcript_id gene_id)] },
    required => 1
);
has 'base_name' => ( is => 'rw', isa => 'Str', required => 1 );
has 'suffix' => ( is => 'rw', isa => 'Str', default => 'bed', required => 1 );
has 'num_output_columns' =>
  ( is => 'rw', isa => 'BedColCount', default => 6, required => 1 );
has 'types_to_convert' => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    default  => sub { [qw(CDS exon gene transcript UTR)] },
    required => 1
);
has 'gene_biotypes_to_convert' => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    default  => sub { [qw(protein_coding pseudogene lincRNA rRNA miRNA)] },
    required => 1,
);

sub convert {
    my ($self) = @_;

    my $in_fh     = $self->in_fh();
    my $out_dir   = $self->out_dir();
    my $base_name = $self->base_name();
    my $suffix    = $self->suffix();

    my $bed_final_col_index = $self->num_output_columns() - 1;

    my $parser = Bio::EnsEMBL::IO::Parser::GTF->open($in_fh);

    my %output_fh;
    for my $type ( @{ $self->types_to_convert } ) {
        for my $biotype ( @{ $self->gene_biotypes_to_convert } ) {
            open( my $out_fh, '>',
                "$out_dir/$base_name.$type.$biotype.$suffix" );
            $output_fh{$type}{$biotype} = $out_fh;
        }
    }

    my $preferred_name_keys = $self->preferred_name_keys;

    while ( $parser->next() ) {
        my $type = $parser->get_raw_type();

        next if ( !$output_fh{$type} );

        my $attributes = $parser->get_attributes;
        my $biotype    = $attributes->{gene_biotype}
          || $attributes
          ->{gene_type};    #gencode and ensembl use different attr names

        next if ( !$output_fh{$type}{$biotype} );

        my $out_fh = $output_fh{$type}{$biotype};

        my @bed = (
            $parser->get_raw_seqname(),
            $parser->get_start() - 1,
            $parser->get_end(), '.',
            $parser->get_raw_score(),
            $parser->get_raw_strand(),
        );

        for my $k (@$preferred_name_keys) {
            if ( $attributes->{$k} ) {
                $bed[3] = $attributes->{$k};
                last;
            }
        }

        print $out_fh join( "\t", @bed[ 0 .. $bed_final_col_index ] ) . "\n";

    }

    for ( values %output_fh ) {
        for my $fh ( values %$_ ) {
            close $fh;
        }
    }

}

__PACKAGE__->meta->make_immutable;
1;
