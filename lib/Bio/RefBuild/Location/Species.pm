package Bio::RefBuild::Location::Species;

use strict;
use Moose;
use namespace::autoclean;

use Bio::RefBuild::Location::Assembly;

with 'Bio::RefBuild::Location::LocationRole';

has 'base_location' =>
  ( is => 'ro', isa => 'Bio::RefBuild::Location::BaseLocation', required => 1 );
has 'species_name' => ( is => 'ro', isa => 'Str', required => 1 );

sub dir_elements {
    my ($self) = @_;
    return ( $self->base_location->dir_elements, $self->species_name );
}

sub list_assemblies {
    my ($self) = @_;
    return $self->list_dirs( $self->location );
}

sub assembly {
    my ( $self, $assembly ) = @_;

    return Bio::RefBuild::Location::Assembly->new(
        species       => $self,
        assembly_name => $assembly,
    );
}

__PACKAGE__->meta->make_immutable;
1;
