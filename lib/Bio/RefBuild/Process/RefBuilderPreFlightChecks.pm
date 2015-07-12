package Bio::RefBuild::Process::RefBuilderPreFlightChecks;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub fetch_input {
    my ($self) = @_;

    # do the executables exist, and are they actually executable?
    my %executables = (
        samtools => $self->param_required('samtools'),
        bowtie1  => $self->param_required('bowtie1'),
        bowtie2  => $self->param_required('bowtie2'),
        bedtools => $self->param_required('bedtools'),
        bwa      => $self->param_required('bwa'),
        java     => $self->param_required('java'),
        bgzip    => $self->param_required('bgzip'),

    );
    for my $executable ( values %executables ) {
        $self->check_executable($executable);
    }
    $self->param_required('picard');

    $self->param_required('assembly_name');
    $self->param_required('species_name');
    $self->param_required('fasta_uri');

    my $root_output_dir = $self->param_required('output_root');
    if ( !-d $root_output_dir ) {
        $self->throw("$root_output_dir is not a directory");
    }

    my $fasta_file = $self->param_required('fasta_file');
    if ( $fasta_file !~ /\.fa\.gz$/ ) {
        $self->throw(
            "$fasta_file should be a gzipped fasta file with the suffix .fa.gz"
        );
    }
    if ( !-e $fasta_file ) {
        $self->throw("$fasta_file does not exist");
    }
}

sub check_executable {
    my ( $self, $executable ) = @_;

    if ( !-x $executable ) {
        $self->throw("$executable is not executable");
    }
}

sub write_output {
    my ($self) = @_;

    my $root     = $self->param_required('output_root');
    my $assembly = $self->param_required('assembly_name');

    my %expected_files = (
        bgzip_fasta => "$root/$assembly/support/$assembly.fa.gz",
        fai         => "$root/$assembly/support/$assembly.fa.gz.fai",
        dict        => "$root/$assembly/support/$assembly.fa.dict",
        chrom_sizes => "$root/$assembly/support/$assembly.sizes",
        temp_fasta  => "$root/$assembly/temp_fasta.fa",
      );

      $self->dataflow_output_id( \%expected_files, 1 );
}

1;
