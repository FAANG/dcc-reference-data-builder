package Bio::RefBuild::Location::Mappability;

use strict;
use Moose;
use namespace::autoclean;

our $DIRNAME = 'mappability';

has 'assembly' =>
  ( is => 'ro', isa => 'Bio::RefBuild::Location::Assembly', required => 1 );
has 'mappability_name' => ( is => 'ro', isa => 'Str', required => 1 );

with 'Bio::RefBuild::Location::LocationRole';

sub dir_elements {
    my ($self) = @_;
    return ( $self->assembly->dir_elements, $DIRNAME, $self->mappability_name );
}

sub _file_path {
  my ($self,$suffix) = @_;
  
  my $file_name = join('.',$self->assembly->assembly_name,$self->mappability_name,$suffix);
  
  return $self->elements_2_path($self->dir_elements,$file_name)
}

sub auc {
  my ($self) = @_;
  return $self->_file_path('auc');
}

sub bw {
  my ($self) = @_;
  return $self->_file_path('bw');
}

sub histogram {
  my ($self) = @_;
  return $self->_file_path('histogram');
}

sub low_mappability {
  my ($self) = @_;
  return $self->_file_path('low_mappability.bed');
}

__PACKAGE__->meta->make_immutable;
1;
