package Bio::RefBuild::Process::RefBuilderPreFlightChecks;

use strict;
use warnings;
use File::Path qw(make_path);
use base ('Bio::EnsEMBL::Hive::Process');
use Bio::RefBuild::Location qw(assembly_location);

sub check_exes {
    my ($self) = @_;

    # do the executables exist, and are they actually executable?
    my %executables = (
        samtools         => $self->param_required('samtools'),
        star             => $self->param_required('star'),
        bedtools         => $self->param_required('bedtools'),
        bwa              => $self->param_required('bwa'),
        java             => $self->param_required('java'),
        gtfToGenePred    => $self->param_required('gtfToGenePred'),
        bedGraphToBigWig => $self->param_required('bedGraphToBigWig'),
        wiggletools      => $self->param_required('wiggletools'),
        cram_seq_cache_populate_script =>
          $self->param_required('cram_seq_cache_populate_script'),
    );
    for my $executable ( values %executables ) {
        if ( !-x $executable ) {
            $self->throw("$executable is not executable");
        }
    }
}

sub check_dirs {
    my ($self) = @_;

    my %dirs = (
        bismark_dir     => $self->param_required('bismark_dir'),
        bowtie1_dir     => $self->param_required('bowtie1_dir'),
        bowtie2_dir     => $self->param_required('bowtie2_dir'),
        rsem_dir        => $self->param_required('rsem_dir'),
        root_output_dir => $self->param_required('output_root'),
        cram_cache_root => $self->param_required('cram_cache_root'),
    );
    for my $dir ( values %dirs ) {
        if ( !-d $dir ) {
            $self->throw("$dir is not a directory");
        }
    }
}

sub fetch_core_requirements {
    my ($self) = @_;

    $self->check_exes();
    $self->check_dirs();
    $self->param_required('picard');

    my $root_output_dir = $self->param_required('output_root');
    my $species         = $self->param_required('species_name');
    my $assembly_name   = $self->param_required('assembly_name');

    $assembly_name = $self->sanitize_file_name($assembly_name);
    $species       = $self->sanitize_file_name($species);

    my $assembly_location =
      assembly_location( $root_output_dir, $species, $assembly_name );

    $self->param( "assembly_filename_base", $assembly_name );
    $self->param( "assembly_output_dir",    $assembly_location->location );
    return $assembly_location;
}

sub fetch_assembly_requirements {
    my ( $self, $assembly_location ) = @_;

    $self->param_required('fasta_uri');

    #TODO
    my $as_index_programs = $self->param_required('assembly_index_programs');

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

sub fetch_annotation_requirements {
    my ( $self, $assembly_location ) = @_;

    my $annot_index_programs =
      $self->param_required('annotation_index_programs');
    my $annotation_name = $self->param_required("annotation_name");
    $annotation_name = $self->sanitize_file_name($annotation_name);

    my $annotation = $assembly_location->annotation($annotation_name);
    my $as         = $assembly_location->assembly_name;

    $self->param( "annotation_output_dir",    $annotation->location );
    $self->param( "annotation_filename_base", $annotation->file_name_base );

    my $gtf_file = $self->param_required('gtf_file');
    if ( $gtf_file !~ /\.gtf\.gz$/ ) {
        $self->throw(
            "$gtf_file should be a gzipped GTF file with the suffix .fa.gz");
    }
    if ( !-e $gtf_file ) {
        $self->throw("$gtf_file does not exist");
    }

    return $annotation;
}

sub fetch_input {
    my ($self) = @_;

    #core requirements
    my $assembly_location = $self->fetch_core_requirements();
    $self->param( "assembly_location", $assembly_location );

    #assembly mode
    if ( $self->param("do_assembly") ) {
        $self->fetch_assembly_requirements($assembly_location);
    }

    #annotation mode
    if ( $self->param("do_annotation") ) {
        my $annotation_location =
          $self->fetch_annotation_requirements($assembly_location);
        $self->param( "annotation_location", $annotation_location );
    }

}

sub run {
    my ($self) = @_;

    my $as_index_programs = $self->param('assembly_index_programs');
    my $assembly_location = $self->param('assembly_location');

    my %dirs_created = (
        dir_base         => $assembly_location->location,
        dir_genome_fasta => $assembly_location->genome_fasta_location,
        dir_mappability  => $assembly_location->mappability_location,
        dir_annotation   => $assembly_location->annotation_location,
    );

    for my $index_prog (@$as_index_programs) {
        $dirs_created{"dir_index_$index_prog"} =
          $assembly_location->genome_index_location($index_prog);
    }

    if ( $self->param("do_annotation") ) {
        my $an_index_programs   = $self->param("annotation_index_programs");
        my $annotation_location = $self->param('annotation_location');

        $dirs_created{"dir_annotation_base"} = $annotation_location->location;

        for my $index_prog (@$an_index_programs) {
            $dirs_created{"dir_annot_index_$index_prog"} =
              $annotation_location->annotation_index_location($index_prog);
        }
    }

    make_path($_) for ( values %dirs_created );

    $self->param( 'dirs_created', \%dirs_created );
}

sub sanitize_file_name {
    my ( $self, $name ) = @_;
    $name =~ s/\W/_/;    # convert non-word chars to _
    $name =~ s/_+/_/;    # remove multiple _ in a row
    $name =~ s/^_+//;    # remove initial _
    $name =~ s/_+$//;    # remove trailing _

    return $name;
}

sub write_output {
    my ($self) = @_;

    my %dirs_created = %{ $self->param('dirs_created') };

    my $fasta_root          = $dirs_created{dir_genome_fasta};
    my $assembly            = $self->param_required('assembly_filename_base');
    my $assembly_output_dir = $self->param("assembly_output_dir");

    my %params_out = (
        assembly_base_name => $assembly,
        fai                => "$fasta_root/$assembly.fa.fai",
        dict               => "$fasta_root/$assembly.dict",
        chrom_sizes        => "$fasta_root/$assembly.sizes",
        fasta              => "$fasta_root/$assembly.fa",
        manifest           => "$assembly_output_dir/files.manifest"
    );

    if ( $self->param("do_annotation") ) {
        my $annotation_root = $dirs_created{"dir_annotation_base"};

        my $annotation = $self->param_required('annotation_filename_base');

        $params_out{annotation_base_name} = $annotation;
        $params_out{gtf}                  = "$annotation_root/$annotation.gtf";
        $params_out{gtf_gz}   = "$annotation_root/$annotation.gtf.gz";
        $params_out{ref_flat} = "$annotation_root/$annotation.ref_flat.gz";
        $params_out{rrna_interval} =
          "$annotation_root/$annotation.rrna.interval";

    }

    $self->dataflow_output_id( { %dirs_created, %params_out }, 1 );
}

1;
