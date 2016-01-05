package Bio::RefBuild::Util::FilterGtfForExons;

use strict;
use namespace::autoclean;
use Moose;
use Bio::EnsEMBL::IO::Parser::GTF;
use List::Util qw(all);
use Data::Dumper;

has 'in_fh'  => ( is => 'rw', isa => 'FileHandle', required => 1 );
has 'out_fh' => ( is => 'rw', isa => 'FileHandle', required => 1 );
has 'required_attributes' => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    required => 1,
    default  => sub { [qw(gene_id transcript_id)] }
);

sub filter {
    my ($self) = @_;

    my @cols = qw(
      seqname source type start end score strand phase attributes
    );

    my $out_fh              = $self->out_fh;
    my @required_attributes = @{ $self->required_attributes };

    print $out_fh
      '# GTF filtered to contain exon entries with required attributes: '
      . join( ', ', @required_attributes ) . "\n";

    my $parser = Bio::EnsEMBL::IO::Parser::GTF->open( $self->in_fh );

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

        my $has_required_attributes =
          all { defined $entry{attrs}{$_} } @required_attributes;

        if (   $entry{type} eq 'exon'
            && $has_required_attributes )
        {
            $entry{attributes} = join ' ',
              map  { $_ . ' "' . $entry{attrs}{$_} . '";' }
              grep { $entry{attrs}{$_} } keys %{ $entry{attrs} };

            print $out_fh join( "\t", map { $_ // '' } @entry{@cols} ) . "\n";
        }
    }

}
1;
