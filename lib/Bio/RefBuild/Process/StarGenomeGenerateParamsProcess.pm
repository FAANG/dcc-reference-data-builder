package Bio::RefBuild::Process::StarGenomeGenerateParamsProcess;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');
use Bio::RefBuild::Util::StarGenomeGenerateParams;
use autodie;

sub fetch_input {
    my ($self) = @_;

    my $fasta = $self->param_required('fasta_file');

}

sub write_output {
    my ($self) = @_;
    my $fasta_file_name = $self->param_required('fasta_file');

    my $in_fh;

    if ( $fasta_file_name =~ m/\.gz$/ ) {
        open( $in_fh, '-|', 'gzip', '-dc', $fasta_file_name );
    }
    else {
        open( $in_fh, '<', $fasta_file_name );
    }

    my $param_calc =
      Bio::RefBuild::Util::StarGenomeGenerateParams->new( fasta_in_fh => $in_fh,
      );

    my $params = $param_calc->calculate_params;

    $self->dataflow_output_id( $params, 1 );
}

1;
