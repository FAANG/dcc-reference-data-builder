package Bio::RefBuild::Location;

use strict;

use Exporter 'import';
our @EXPORT_OK = qw(assembly_location);

use Bio::RefBuild::Location::BaseLocation;

sub assembly_location {
    my ( $root_dir, $species, $assembly ) = @_;

    return Bio::RefBuild::Location::BaseLocation->new(base_dir => $root_dir)
      ->species($species)->assembly($assembly);
}

1;