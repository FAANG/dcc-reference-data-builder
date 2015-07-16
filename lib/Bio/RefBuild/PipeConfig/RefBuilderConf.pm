package Bio::RefBuild::PipeConfig::RefBuilderConf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

my %foo = {
    "dir_annot_index_rsem" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/test1_gencode/rsem",
    "dir_annot_index_rsem_polya" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/test1_gencode/rsem_polya",
    "dir_annot_index_star" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/test1_gencode/star",
    "dir_annotation" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/annotation",
    "dir_annotation_base" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/test1_gencode",
    "dir_base" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1",
    "dir_genome_fasta" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/genome_fasta",
    "dir_index_bismark" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/genome_index/bismark",
    "dir_index_bowtie1" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/genome_index/bowtie1",
    "dir_index_bowtie2" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/genome_index/bowtie2",
    "dir_index_bwa" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/genome_index/bwa",
    "dir_mappability" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/mappability",
    "dir_split_genome_fasta" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/genome_fasta/split_fasta",
    "fai" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/genome_fasta/ta1.fa.gz.fai",
    "fasta" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/genome_fasta/ta1.fa",
    "gtf" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/test1_gencode/ta1_test1_gencode.gtf",
    "gtf_gz" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/test1_gencode/ta1_test1_gencode.gtf.gz",
    "manifest" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/files.manifest",
    "ref_flat" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/test1_gencode/ta1_test1_gencode.ref_flat.gz",
    "rrna_interval" =>
"/nfs/production/reseq-info/work/davidr/ref_builder/ref_files/Homo_sapiens/ta1/test1_gencode/ta1_test1_gencode.rrna.interval"
};

sub pipeline_wide_parameters {
    my ($self) = @_;
    return {
        %{ $self->SUPER::pipeline_wide_parameters },

        #required executables
        samtools                  => $self->o('samtools'),
        bowtie1_dir               => $self->o('bowtie1_dir'),
        bowtie2_dir               => $self->o('bowtie2_dir'),
        rsem_dir                  => $self->o('rsem_dir'),
        picard                    => $self->o('picard'),
        java                      => $self->o('java'),
        bedtools                  => $self->o('bedtools'),
        bwa                       => $self->o('bwa'),
        bgzip                     => $self->o('bgzip'),
        star                      => $self->o('star'),
        gtfToGenePred             => $self->o('gtfToGenePred'),
        bismark_dir               => $self->o('bismark_dir'),
        output_root               => $self->o('output_root'),
        assembly_index_programs   => $self->o('assembly_index_programs'),
        annotation_index_programs => $self->o('annotation_index_programs'),
    };
}

sub default_options {
    my ($self) = @_;
    return {
        %{ $self->SUPER::default_options() },
        assembly_index_programs   => [qw(bismark bwa bowtie1 bowtie2)],
        annotation_index_programs => [qw(rsem rsem_polya star)],
        pipeline_name             => 'ref_builder',
    };
}

=head Parameters
  Required options:
  executables / dirs ( always required, should be set in options at setup )
    samtools
    star
    bedtools
    bwa
    java
    bgzip
    gtfToGenePred
    bismark_dir
    bowtie1_dir
    bowtie2_dir
    rsem_dir
    picard(jar)
    output_root

  Required in input:
  start_* parameters( we always need these )
    root_output_dir
    species_name
    assembly_name

  start_assembly parameters
    fasta_file
    fasta_uri

  start_annotation parameters
    gtf_file
    annotation_name

  Parameters created by start_assembly:
    dir_base
    dir_annotation
    dir_genome_fasta
    dir_mappability
    dir_split_genome_fasta
    dir_index_bismark
    dir_index_bowtie1
    dir_index_bowtie2
    dir_index_bwa

    manifest
    assembly_base_name
    bgzip_fasta
    fasta
    chrom_sizes
    dict
    fai

  Additional Parameters created by start_annotation:
    dir_index_rsem
    dir_index_rsem_polya
    dir_index_star

    annotation_base_name
    gtf                 
    gtf_gz
    ref_flat
    rrna_interval

=cut

sub pipeline_analyses {
    my ($self) = @_;
    return [
        #entry points
        {
            -logic_name => 'start_assembly',
            -module     => 'Bio::RefBuild::Process::RefBuilderPreFlightChecks',
            -rc_name    => 'default',
            -parameters => {
                do_assembly   => 1,
                do_annotation => 0,
            },
            -flow_into => ['process_fasta'],
        },
        {
            -logic_name => 'start_annotation',
            -module     => 'Bio::RefBuild::Process::RefBuilderPreFlightChecks',
            -rc_name    => 'default',
            -parameters => {
                do_assembly   => 0,
                do_annotation => 1,

            },
            -flow_into => [ 'cp_annotation', 'unzip_annotation' ],
        },
        {
            -logic_name => 'start_manifest',
            -module     => 'Bio::RefBuild::Process::RefBuilderPreFlightChecks',
            -rc_name    => 'default',
            -parameters => {
                do_assembly   => 1,
                do_annotation => 0,
            },
            -flow_into => ['write_manifest'],
        },

        #final job
        {
            -logic_name => 'write_manifest',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => {
                cmd =>
'find #dir_base# -type f -printf \'%p\t%s\t\' -execdir sh -c \'md5sum "{}" | sed s/\ .*//\' \; > #manifest#',
            },
        },

        #assembly processes
        {
            -logic_name => 'process_fasta',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters => {
                cmd =>
'gunzip -c #fasta_file# | tee #fasta# | #bgzip# -c > #bgzip_fasta#',
            },
            -flow_into => [ 'support_files', 'assembly_indexing', ],
        },
        {
            -logic_name  => 'support_files',
            -module      => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -meadow_type => 'LOCAL',
            -flow_into   => [ 'samtools_fai', 'picard_dict' ],
        },
        {
            -logic_name  => 'assembly_indexing',
            -module      => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -meadow_type => 'LOCAL',
            -flow_into   => [
                'bowtie1_index', 'bowtie2_index',
                'bwa_index',     'pre_bismark_index',
            ],
        },
        {
            -logic_name => 'samtools_fai',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => { cmd => '#samtools# faidx #bgzip_fasta#', },
            -flow_into  => ['chrom_sizes'],
        },
        {
            -logic_name => 'chrom_sizes',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => { cmd => 'cut -f1,2 #fai# > #chrom_sizes#', },
        },
        {
            -logic_name => 'picard_dict',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '1Gb_job',
            -parameters => {
                cmd =>
'rm -f #dict# ; #java# -jar #picard# CreateSequenceDictionary REFERENCE=#bgzip_fasta# OUTPUT=#dict# GENOME_ASSEMBLY="#assembly_name#" SPECIES="#species_name#" URI="#fasta_uri#"',
            },
        },
        {
            -logic_name => 'bwa_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '5Gb_job',
            -parameters => {
                cmd =>
'#bwa# index -p #dir_index_bwa#/#assembly_base_name# #bgzip_fasta#',
            },
        },
        {
            -logic_name => 'bowtie1_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '6Gb_job',
            -parameters => {
                cmd =>
'#bowtie1_dir#/bowtie-build -q #fasta# #dir_index_bowtie1#/#assembly_base_name#',
            },
        },
        {
            -logic_name => 'bowtie2_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '6Gb_job',
            -parameters => {
                cmd =>
'#bowtie2_dir#/bowtie2-build -q #fasta# #dir_index_bowtie2#/#assembly_base_name#',
            },
        },
        {
            -logic_name => 'pre_bismark_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => {
                cmd => 'cp #fasta# #dir_index_bismark#/#assembly_base_name#.fa',
            },
            -flow_into => ['bismark_index'],
        },
        {
            -logic_name => 'bismark_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '6Gb_job',
            -parameters => {
                cmd =>
'#bismark_dir#/bismark_genome_preparation --path_to_bowtie #bowtie1_dir# --yes_to_all #dir_index_bismark#',
            },
            -flow_into => ['post_bismark_index'],
        },
        {
            -logic_name => 'post_bismark_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters =>
              { cmd => 'rm -f #dir_index_bismark#/#assembly_base_name#.fa', },
        },

        #annotation processes
        {
            -logic_name => 'cp_annotation',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => { cmd => 'cp #gtf_file# #gtf_gz#', },
            -flow_into  => ['ref_flat'],
        },
        {
            -logic_name => 'unzip_annotation',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => { cmd => 'gunzip -c #gtf_file# > #gtf#', },
            -flow_into  => [ 'annotation_indexing', 'rrna_interval' ],
        },
        {
            -logic_name => 'ref_flat',

# adapted fromhttps://gist.github.com/igordot/4467f1b02234ff864e61 ref flat from gtf
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '400Mb_job',
            -parameters => {
                cmd =>
'#gtfToGenePred# -genePredExt -geneNameAsName2 #gtf# /dev/stdout | awk \'BEGIN{OFS="\t";FS="\t"}{print $12,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10}\' | gzip -c > #ref_flat#',
            },
        },
        {
            -logic_name  => 'annotation_indexing',
            -module      => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -meadow_type => 'LOCAL',
            -flow_into   => [ 'rsem_index', 'rsem_polya_index', 'star_index', ],
        },

        {
            -logic_name => 'rrna_interval',
            -module     => 'Bio::RefBuild::Process::GtfToRrnaIntervalProcess',
            -rc_name    => '200Mb_job',
            -parameters => {
                gtf           => '#gtf',
                dict          => '#dict#',
                rrna_interval => '#rrna_interval#'
            },
        },

        {
            -logic_name => 'star_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'star_job',
            -parameters => {
                cmd =>
'#star# --runMode genomeGenerate --runThreadN 4 --genomeDir #dir_annot_index_star# --genomeFastaFiles #fasta# --sjdbGTFfile #gtf#',
            },
        },
        {
            -logic_name => 'rsem_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '1Gb_job',
            -parameters => {
                cmd =>
'#rsem_dir#/rsem-prepare-reference -q --gtf #gtf# --bowtie --bowtie-path #bowtie1_dir# --bowtie2 --bowtie2-path #bowtie2_dir# #fasta# #dir_annot_index_rsem#/#annotation_base_name#'
            },
        },
        {
            -logic_name => 'rsem_polya_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '1Gb_job',
            -parameters => {
                cmd =>
'#rsem_dir#/rsem-prepare-reference -q --polyA --gtf #gtf# --bowtie --bowtie-path #bowtie1_dir# --bowtie2 --bowtie2-path #bowtie2_dir# #fasta# #dir_annot_index_rsem_polya#/#annotation_base_name#_polya'
            },
        },

    ];
}

sub resource_classes {
    my ($self) = @_;
    return {
        %{ $self->SUPER::resource_classes }
        ,    # inherit 'default' from the parent class

        'default' => { 'LSF' => '-M50   -R"select[mem>50]   rusage[mem=50]"' },
        '200Mb_job' =>
          { 'LSF' => '-M200   -R"select[mem>200]   rusage[mem=200]"' },
        '400Mb_job' =>
          { 'LSF' => '-M400   -R"select[mem>400]   rusage[mem=400]"' },
        '1Gb_job' =>
          { 'LSF' => '-M1000  -R"select[mem>1000]  rusage[mem=1000]"' },
        '2Gb_job' =>
          { 'LSF' => '-M2000  -R"select[mem>2000]  rusage[mem=2000]"' },
        '3Gb_job' =>
          { 'LSF' => '-M3000  -R"select[mem>3000]  rusage[mem=3000]"' },
        '5Gb_job' =>
          { 'LSF' => '-M5000  -R"select[mem>5000]  rusage[mem=5000]"' },
        '6Gb_job' =>
          { 'LSF' => '-M6000  -R"select[mem>6000]  rusage[mem=6000]"' },
        'star_job' => {
            'LSF' =>
'-M31000 -n4 -R"span[hosts=1]  select[mem>31000] rusage[mem=31000]"'
        },
    };
}

sub hive_meta_table {
    my ($self) = @_;
    return { %{ $self->SUPER::hive_meta_table }, 'hive_use_param_stack' => 1, };
}
1;
