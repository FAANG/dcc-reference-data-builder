package Bio::RefBuild::Util::SplitFasta;

use Moose;
use PerlIO::gzip;

has 'output_dir'  => ( is => 'rw', isa => 'Str' );
has 'fasta_in_fh' => ( is => 'rw', isa => 'FileHandle' );
has 'gzip_output'    => ( is => 'rw', isa => 'Bool' );

sub split {
    my ($self) = @_;

    my $dir   = $self->output_dir();
    my $in_fh = $self->fasta_in_fh();
    my $do_gzip = $self->gzip_output();

    local $/ = '>';

    my @file_names;

    while (<$in_fh>) {
        chomp;
        if (m/^(\S+)/) {
            my $name        = $1;

            my $output_path = "$dir/$name.fa";
            my $output_layer = '>';
            if ($do_gzip){
              $output_path .= '.gz';
              $output_layer .= ':gzip';
            }
            
            push @file_names, $output_path;

            open( my $fh, $output_layer, $output_path );

            print $fh $/;
            print $fh $_;

            close $fh;
        }
    }
    return \@file_names;
}

1;
