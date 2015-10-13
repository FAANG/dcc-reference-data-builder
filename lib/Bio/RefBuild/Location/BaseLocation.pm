package Bio::RefBuild::Location::BaseLocation;

use Moose;
use namespace::autoclean;
use Bio::RefBuild::Location::Species;

with 'Bio::RefBuild::Location::LocationRole';

has 'base_dir' => ( is => 'ro', isa => 'Str', required => 1 );


sub dir_elements {
  my ($self) = @_;
  return ($self->base_dir);
}

sub list_species {
    my ($self) = @_;
    return $self->list_dirs( $self->base_dir );
}

sub species {
    my ( $self, $species ) = @_;

    return Bio::RefBuild::Location::Species->new(
        base_location => $self,
        species_name       => $species
    );
}


__PACKAGE__->meta->make_immutable;
1;
