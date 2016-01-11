package Bio::RefBuild::Util::GtfToRrnaInterval;

use strict;
use Moose;
use Bio::EnsEMBL::IO::Parser::GTF;
use namespace::autoclean;

has 'in_fh'   => ( is => 'rw', isa => 'FileHandle' );
has 'out_fh'  => ( is => 'rw', isa => 'FileHandle' );
has 'dict_fh' => ( is => 'rw', isa => 'FileHandle' );

#based on the gists here: https://www.biostars.org/p/67079/
sub convert {
    my ($self) = @_;

    my $in_fh   = $self->in_fh();
    my $out_fh  = $self->out_fh();
    my $dict_fh = $self->dict_fh();

    my $parser = Bio::EnsEMBL::IO::Parser::GTF->open($in_fh);

    while (<$dict_fh>) {
        print $out_fh $_;
    }

    while ( $parser->next() ) {
        my $attributes    = $parser->get_attributes;
        my $transcript_id = $attributes->{transcript_id} || $attributes->{ID};
        my $gene_type =
             $attributes->{gene_type}
          || $attributes->{gene_biotype}
          || '';

        print $gene_type . "\n";
        if (
            (
                   $parser->get_type() eq 'transcript'
                && $transcript_id
                && $gene_type eq 'rRNA'
            )
            || $parser->get_type() eq 'rRNA'
          )
        {
            print $out_fh join( "\t",
                $parser->get_raw_seqname(),
                $parser->get_start(),
                $parser->get_end(), $parser->get_raw_strand(),
                $transcript_id )
              . $/;
        }
    }
}
__PACKAGE__->meta->make_immutable;
1;
