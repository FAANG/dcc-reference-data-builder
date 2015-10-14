package Bio::RefBuild::Location::LocationRole;

use strict;
use Moose::Role;
use autodie;

requires 'dir_elements';

sub location {
    my ($self) = @_;
    
    my @dir_elements = $self->dir_elements;
    my $path = $self->elements_2_path( @dir_elements );
    
    
    return $path;
}

sub exists {
    my ($self) = @_;
    return -e $self->location;
}

sub elements_2_path {
    my ( $self, @elements ) = @_;

    my $path = join( '/', @elements );

    $path =~ s!/+!/!g;
    return $path;
}

sub list_dirs {
    my ( $self, $location ) = @_;

    opendir( my $dh, $location );

    my @dirs = sort grep { -d "$location/$_" && !/^\.{1,2}$/ } readdir($dh);
    
    closedir($dh);

    return @dirs;
}

1;
