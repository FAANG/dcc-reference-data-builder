package Bio::RefBuild::Process::RefBuilderPreFlightChecks;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

sub fetch_input {
    my ($self) = @_;

    # do the executables exist, and are they actually executable?
    my %executables = (
        samtools      => $self->param_required('samtools'),
        star          => $self->param_required('star'),
        bedtools      => $self->param_required('bedtools'),
        bwa           => $self->param_required('bwa'),
        java          => $self->param_required('java'),
        bgzip         => $self->param_required('bgzip'),
        gtfToGenePred => $self->param_required('gtfToGenePred'),

    );
    for my $executable ( values %executables ) {
        $self->check_executable($executable);
    }

    $self->param_required('picard');
    $self->param_required('assembly_name');
    $self->param_required('annotation_name');
    $self->param_required('species_name');
    $self->param_required('fasta_uri');

    my %dirs = (
        bismark_dir     => $self->param_required('bismark_dir'),
        bowtie1_dir     => $self->param_required('bowtie1_dir'),
        bowtie2_dir     => $self->param_required('bowtie2_dir'),
        rsem_dir        => $self->param_required('rsem_dir'),
        root_output_dir => $self->param_required('output_root'),
    );
    for my $dir ( values %dirs ) {
        if ( !-d $dir ) {
            $self->throw("$dir is not a directory");
        }
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
    my $gtf_file = $self->param_required('gtf_file');
    if ( $gtf_file !~ /\.gtf\.gz$/ ) {
        $self->throw(
            "$fasta_file should be a gzipped GTF file with the suffix .fa.gz");
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

    my $root            = $self->param_required('output_root');
    my $assembly        = $self->param_required('assembly_name');
    my $annotation_name = $self->param_required('annotation_name');

    my %expected_files = (
        bgzip_fasta => "$root/$assembly/fasta/$assembly.fa.gz",
        fai         => "$root/$assembly/fasta/$assembly.fa.gz.fai",
        gtf         => "$root/$assembly/annotation/$annotation_name.gtf.gz",
        dict        => "$root/$assembly/fasta/$assembly.dict",
        chrom_sizes => "$root/$assembly/support/$assembly.sizes",
        temp_fasta  => "$root/$assembly/temp_fasta.fa",
        temp_gtf    => "$root/$assembly/temp_gtf.gtf",
    );

    $self->dataflow_output_id( \%expected_files, 1 );
}

1;
