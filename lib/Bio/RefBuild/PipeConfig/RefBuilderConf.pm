package Bio::RefBuild::PipeConfig::RefBuilderConf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

sub pipeline_wide_parameters {
    my ($self) = @_;
    return {
        %{ $self->SUPER::pipeline_wide_parameters },

        #required executables
        samtools      => $self->o('samtools'),
        bowtie1_dir   => $self->o('bowtie1_dir'),
        bowtie2_dir   => $self->o('bowtie2_dir'),
        rsem_dir      => $self->o('rsem_dir'),
        picard        => $self->o('picard'),
        java          => $self->o('java'),
        bedtools      => $self->o('bedtools'),
        bwa           => $self->o('bwa'),
        bgzip         => $self->o('bgzip'),
        star          => $self->o('star'),
        gtfToGenePred => $self->o('gtfToGenePred'),
        bismark_dir   => $self->o('bismark_dir'),
    };
}

sub default_options {
    my ($self) = @_;
    return {
        %{ $self->SUPER::default_options() },
        index_programs =>
          [qw(bismark bwa bowtie1 bowtie2 rsem rsem_polya star)],
        pipeline_name => 'ref_builder',
    };
}

sub pipeline_analyses {
    my ($self) = @_;
    return [
        {
            -logic_name => 'start',
            -module     => 'Bio::RefBuild::Process::RefBuilderPreFlightChecks',
            -rc_name    => 'default',
            -flow_into  => ['make_dirs'],
        },
        {
            -logic_name => 'make_dirs',
            -module     => 'Bio::RefBuild::Process::CreateDirs',
            -rc_name    => 'default',
            -parameters => { index_programs => $self->o('index_programs') },
            -flow_into  => [ 'cp_annotation', ],
        },
        {
            -logic_name => 'cp_annotation',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => { cmd => 'cp #gtf_file# #gtf#', },
            -flow_into  => [ 'unzip_annotation', 'ref_flat' ],
        },
        {
            -logic_name => 'unzip_annotation',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => { cmd => 'gunzip -c #gtf# > #temp_gtf#', },
            -flow_into  => [ 'process_fasta', ],
        },
        {
            -logic_name => 'ref_flat',

# adapted fromhttps://gist.github.com/igordot/4467f1b02234ff864e61 ref flat from gtf
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '400Mb_job',
            -parameters => {
                cmd =>
'#gtfToGenePred# -genePredExt -geneNameAsName2 #gtf# /dev/stdout | awk \'BEGIN{OFS="\t";FS="\t"}{print $12,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10}\' | gzip -c > #dir_annotation#/#annotation_name#.ref_flat.gz',
            },
        },
        {
            -logic_name => 'process_fasta',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters => {
                cmd =>
'gunzip -c #fasta_file# | tee #temp_fasta# | #bgzip# -c > #bgzip_fasta#',
            },
            -flow_into => {
                '1->A' => [ 'support_files', 'indexing', ],
                'A->1' => ['rm_temp_files']
            },
        },
        {
            -logic_name  => 'support_files',
            -module      => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -meadow_type => 'LOCAL',
            -flow_into   => [ 'samtools_fai', 'picard_dict' ],
        },
        {
            -logic_name  => 'indexing',
            -module      => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -meadow_type => 'LOCAL',
            -flow_into   => [
                'bowtie1_index', 'bowtie2_index',
                'star_index',    'bwa_index',
                'rsem_index',    'rsem_polya_index',
                'pre_bismark_index'
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
            -flow_into => ['rrna_interval'],
        },
        {
            -logic_name => 'rrna_interval',
            -module     => 'Bio::RefBuild::Process::GtfToRrnaIntervalProcess',
            -rc_name    => '200Mb_job',
            -parameters => {
                rrna_interval =>
                  '#dir_annotation#/#assembly_name#.rrna.interval'
            },
        },
        {
            -logic_name => 'bwa_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '5Gb_job',
            -parameters => {
                cmd =>
'#bwa# index -p #dir_index_bwa#/#assembly_name# #bgzip_fasta#',
            },
        },
        {
            -logic_name => 'bowtie1_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '6Gb_job',
            -parameters => {
                cmd =>
'#bowtie1_dir#/bowtie-build -q #temp_fasta# #dir_index_bowtie1#/#assembly_name#',
            },
        },
        {
            -logic_name => 'bowtie2_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '6Gb_job',
            -parameters => {
                cmd =>
'#bowtie2_dir#/bowtie2-build -q #temp_fasta# #dir_index_bowtie2#/#assembly_name#',
            },
        },
        {
            -logic_name => 'star_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'star_job',
            -parameters => {
                cmd =>
'#star# --runMode genomeGenerate --runThreadN 4 --genomeDir #dir_index_star# --genomeFastaFiles #temp_fasta# --sjdbGTFfile #temp_gtf#',
            },
        },
        {
            -logic_name => 'rsem_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '1Gb_job',
            -parameters => {
                cmd =>
'#rsem_dir#/rsem-prepare-reference -q --gtf #temp_gtf# --bowtie --bowtie-path #bowtie1_dir# --bowtie2 --bowtie2-path #bowtie2_dir# #temp_fasta# #dir_index_rsem#/#annotation_name#'
            },
        },
        {
            -logic_name => 'rsem_polya_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '1Gb_job',
            -parameters => {
                cmd =>
'#rsem_dir#/rsem-prepare-reference -q --polyA --gtf #temp_gtf# --bowtie --bowtie-path #bowtie1_dir# --bowtie2 --bowtie2-path #bowtie2_dir# #temp_fasta# #dir_index_rsem_polya#/#annotation_name#'
            },
        },
        {
            -logic_name => 'pre_bismark_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => {
                cmd => 'cp #temp_fasta# #dir_index_bismark#/#assembly_name#.fa',
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
        },
        {
            -logic_name => 'rm_temp_files',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => { cmd => 'rm #temp_fasta# #temp_gtf#', }
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
