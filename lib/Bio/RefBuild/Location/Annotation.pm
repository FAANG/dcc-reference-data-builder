package Bio::RefBuild::Location::Annotation;

use strict;
use Moose;
use namespace::autoclean;

use Bio::RefBuild::Location::Assembly;

has 'assembly' =>
  ( is => 'ro', isa => 'Bio::RefBuild::Location::Assembly', required => 1 );
has 'annotation_name' => ( is => 'ro', isa => 'Str', required => 1 );



with 'Bio::RefBuild::Location::LocationRole';

our $DIRNAME = 'annotation';

sub dir_elements {
    my ($self) = @_;
    return ( $self->assembly->dir_elements, $DIRNAME, $self->annotation_name );
}

sub file_name_base {
    my ($self) = @_;
    return $self->assembly->assembly_name . '_' . $self->annotation_name;
}

sub gtf {
    my ($self) = @_;
    return $self->location . '/' . $self->file_name_base . '.gtf';
}

sub exon_filtered_gtf {
    my ($self) = @_;
    return $self->location . '/' . $self->file_name_base . '.exon_filtered.gtf';
}

sub ref_flat {
    my ($self) = @_;
    return $self->location . '/' . $self->file_name_base . '.ref_flat';
}

sub rrna_interval {
    my ($self) = @_;
    return $self->location . '/' . $self->file_name_base . '.rrna_interval';
}

sub list_annotation_indices {
    my ($self) = @_;
    return $self->list_dirs( $self->elements_2_path( $self->dir_elements ) );
}

sub annotation_index_location {
    my ( $self, $program ) = @_;

    return $self->elements_2_path( $self->dir_elements, $program );
}

__PACKAGE__->meta->make_immutable;
1;
