package Bio::RefBuild::Process::SplitFastaProcess;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

use autodie;
use Bio::RefBuild::Util::SplitFasta;
use PerlIO::gzip;

  sub fetch_input {
    my ($self) = @_;

    my $fasta      = $self->param_required('fasta_file');
    my $output_dir = $self->param_required('output_dir');
    my $do_gzip    = $self->param('do_gzip');
}

sub write_output {
    my ($self) = @_;

    my $fasta_file_name = $self->param_required('fasta_file');
    my $output_dir      = $self->param_required('output_dir');
    my $do_gzip         = $self->param('do_gzip');

    my $in_fh;

    if ( $fasta_file_name =~ m/\.gz$/ ) {
        open( $in_fh, '<:gzip', $fasta_file_name );
    }
    else {
        open( $in_fh, '<', $fasta_file_name );
    }

    my $splitter = Bio::RefBuild::Util::SplitFasta->new(
        output_dir  => $output_dir,
        fasta_in_fh => $in_fh,
        gzip_output => $do_gzip,
    );

    my @files_created = $splitter->split();

    close($in_fh);

    $self->dataflow_output_id( { split_fasta_files => \@files_created }, 1 );
}

1;
