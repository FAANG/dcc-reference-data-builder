package Bio::RefBuild::PipeConfig::RefBuilderConf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

sub pipeline_wide_parameters {
    my ($self) = @_;
    return {
        %{ $self->SUPER::pipeline_wide_parameters },
        samtools => $self->o('samtools'),
        bowtie1  => $self->o('bowtie1'),
        bowtie2  => $self->o('bowtie2'),
        picard   => $self->o('picard'),
        java     => $self->o('java'),
        bedtools => $self->o('bedtools'),
        bwa      => $self->o('bwa'),
        bgzip    => $self->o('bgzip'),
    };
}

sub default_options {
    my ($self) = @_;
    return {
        %{ $self->SUPER::default_options() },
        index_programs => [qw(bwa bowtie1 bowtie2)],
        pipeline_name  => 'ref_builder',
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
            -flow_into  => [ 'bgzip_fasta', 'split_fasta' ],
        },
        {
            -logic_name => 'bgzip_fasta',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters =>
              { cmd => 'gunzip -c #fasta_file# | #bgzip# -c > #bgzip_fasta#', },
            -flow_into => [
                'samtools_fai',
                'picard_dict',

                #TODO          'cp_annotation,
                'bwa_index',
            ]
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
            -rc_name    => 'default',
            -parameters => {
                cmd =>
'#java# -jar #picard# CreateSequenceDictionary REFERENCE=#bgzip_fasta# OUTPUT=#dict# GENOME_ASSEMBLY=#assembly_name# SPECIES="#species_name#" URI="#fasta_uri#"',
            },
        },
        {
            -logic_name => 'split_fasta',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => {
                cmd =>
'gunzip -c #fasta_file# | tee #temp_fasta# | awk \'/^>/{OUT= "#dir_fasta#/" substr($1,2) ".fa"};{print >> OUT; close(OUT)}\'',
            },
            -flow_into => {
                '2->A' => [ 'bowtie1_index', 'bowtie2_index' ],
                'A->1' => ['rm_temp_fasta']
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
            -rc_name    => '5Gb_job',
            -parameters => {
                cmd =>
'#bowtie1# -q #temp_fasta# #dir_index_bowtie1#/#assembly_name#',
            },
        },
        {
            -logic_name => 'bowtie2_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '5Gb_job',
            -parameters => {
                cmd =>
'#bowtie2# -q #temp_fasta# #dir_index_bowtie2#/#assembly_name#',
            },
        },
        {
            -logic_name => 'rm_temp_fasta',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'default',
            -parameters => {
                cmd => 'rm #temp_fasta#',
            },
        },

    ];
}

sub resource_classes {
    my ($self) = @_;
    return {
        %{ $self->SUPER::resource_classes }
        ,    # inherit 'default' from the parent class

        'default' => { 'LSF' => '-M50   -R"select[mem>50]   rusage[mem=50]"' }
        ,    # to make sure it fails similarly on both farms
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
    };
}

sub hive_meta_table {
    my ($self) = @_;
    return { %{ $self->SUPER::hive_meta_table }, 'hive_use_param_stack' => 1, };
}
1;
