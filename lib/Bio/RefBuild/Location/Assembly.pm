package Bio::RefBuild::Location::Assembly;

use strict;
use Moose;
use namespace::autoclean;

use Bio::RefBuild::Location::Mappability;
use Bio::RefBuild::Location::Annotation;

with 'Bio::RefBuild::Location::LocationRole';

has 'species' =>
  ( is => 'ro', isa => 'Bio::RefBuild::Location::Species', required => 1 );
has 'assembly_name' => ( is => 'ro', isa => 'Str', required => 1 );

our $GENOME_FASTA_DIR = 'genome_fasta';
our $GENOME_INDEX_DIR = 'genome_index';

sub dir_elements {
    my ($self) = @_;
    return ( $self->species->dir_elements, $self->assembly_name );
}

sub annotation {
    my ( $self, $annotation ) = @_;
    return Bio::RefBuild::Location::Annotation->new(
        assembly        => $self,
        annotation_name => $annotation
    );
}

sub list_annotation {
    my ($self) = @_;
    return $self->list_dirs( $self->annotation_location );
}

sub mappability {
    my ( $self, $mappability ) = @_;
    return Bio::RefBuild::Location::Mappability->new(
        assembly         => $self,
        mappability_name => $mappability
    );
}

sub list_mappability {
    my ($self) = @_;
    return $self->list_dirs( $self->mappability_location );
}

sub genome_index_location {
    my ( $self, $program_name ) = @_;
    return $self->elements_2_path( $self->dir_elements, $GENOME_INDEX_DIR,
        $program_name );
}

sub list_genome_indices {
    my ($self) = @_;
    return $self->list_dirs(
        $self->elements_2_path( $self->dir_elements, $GENOME_INDEX_DIR ) );
}

sub genome_fasta_location {
    my ($self) = @_;
    return $self->elements_2_path( $self->dir_elements, $GENOME_FASTA_DIR );
}

sub mappability_location {
    my ($self) = @_;
    return $self->elements_2_path( $self->dir_elements,
        $Bio::RefBuild::Location::Mappability::DIRNAME );
}

sub annotation_location {
    my ($self) = @_;
    return $self->elements_2_path( $self->dir_elements,
        $Bio::RefBuild::Location::Annotation::DIRNAME );
}

sub manifest_location {
    my ($self) = @_;
    return $self->location() . '/files.manifest';
}

sub seq_dict {
    my ($self) = @_;
    return
      $self->genome_fasta_location . '/' . $self->assembly_name() . '.dict';
}

sub fasta {
    my ($self) = @_;
    return $self->genome_fasta_location . '/' . $self->assembly_name() . '.fa';
}

sub fai {
    my ($self) = @_;
    return
        $self->genome_fasta_location . '/'
      . $self->assembly_name()
      . '.fa.fai';
}

sub chrom_sizes {
    my ($self) = @_;
    return
        $self->genome_fasta_location . '/'
      . $self->assembly_name()
      . '.sizes';
}

__PACKAGE__->meta->make_immutable;
1;
