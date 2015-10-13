#!/usr/bin/env perl
use strict;

use FindBin qw($Bin);
use File::Temp qw/ tempdir /;
use lib "$Bin/../lib";
use autodie;
use Data::Dumper;
use Test::More;
use Bio::EnsEMBL::Hive::Utils::Test qw(standaloneJob);

my $output_base = "$Bin/fake/Homo_sapiens";
my $annotation =
  "$output_base/grch38/annotation/gencode22/grch38_gencode22";
my $fake_exe  = "$Bin/fake/fake_exe";
my $fake_data = "$Bin/fake/fake_data";

standaloneJob(
    'Bio::RefBuild::Process::RefBuilderPreFlightChecks',

    #input
    {
        #overall_control
        do_assembly   => 1,
        do_annotation => 1,

        #misc
        assembly_index_programs   => [qw(bismark bwa bowtie1 bowtie2)],
        annotation_index_programs => [qw(rsem rsem_polya star)],
        pipeline_name             => 'ref_builder',
        cram_cache_num_subdirs    => 2,

        #programs
        samtools                       => $fake_exe,
        star                           => $fake_exe,
        bedtools                       => $fake_exe,
        bwa                            => $fake_exe,
        java                           => $fake_exe,
        gtfToGenePred                  => $fake_exe,
        bedGraphToBigWig               => $fake_exe,
        wiggletools                    => $fake_exe,
        cram_seq_cache_populate_script => $fake_exe,
        picard                         => $fake_exe,

        #dirs
        bismark_dir     => "$Bin/fake",
        bowtie1_dir     => "$Bin/fake",
        bowtie2_dir     => "$Bin/fake",
        rsem_dir        => "$Bin/fake",
        output_root     => "$Bin/fake",
        cram_cache_root => "$Bin/fake",

        #input data
        assembly_name => 'grch38',
        fasta_uri => 'http://url.to/GRCh38_no_alt_analysis_set.201503031.fa.gz',
        fasta_file      => "$fake_data.fa.gz",
        species_name    => 'Homo sapiens',
        kmer_sizes      => '42,50,100,150,200',
        annotation_name => 'gencode22',
        gtf_file        => "$fake_data.gtf.gz" },
    [
        [
            'DATAFLOW',
            {
                #dirs
                dir_base         => "$output_base/grch38",
                dir_genome_fasta => "$output_base/grch38/genome_fasta",
                dir_mappability  => "$output_base/grch38/mappability",
                dir_annotation   => "$output_base/grch38/annotation",
                dir_annotation_base =>
                  "$output_base/grch38/annotation/gencode22",
                  
                dir_index_bismark => "$output_base/grch38/genome_index/bismark",
                dir_index_bwa     => "$output_base/grch38/genome_index/bwa",
                dir_index_bowtie1 => "$output_base/grch38/genome_index/bowtie1",
                dir_index_bowtie2 => "$output_base/grch38/genome_index/bowtie2",

                dir_annot_index_rsem =>
                  "$output_base/grch38/annotation/gencode22/rsem",
                dir_annot_index_rsem_polya =>
                  "$output_base/grch38/annotation/gencode22/rsem_polya",
                dir_annot_index_star =>
                  "$output_base/grch38/annotation/gencode22/star",

                #misc
                manifest => "$output_base/grch38/files.manifest",

                #assembly
                assembly_base_name => 'grch38',
                fai         => "$output_base/grch38/genome_fasta/grch38.fa.fai",
                dict        => "$output_base/grch38/genome_fasta/grch38.dict",
                chrom_sizes => "$output_base/grch38/genome_fasta/grch38.sizes",
                fasta       => "$output_base/grch38/genome_fasta/grch38.fa",

                #annotation
                annotation_base_name => 'grch38_gencode22',
                gtf                  => "$annotation.gtf",
                gtf_gz               => "$annotation.gtf.gz",
                ref_flat             => "$annotation.ref_flat.gz",
                rrna_interval        => "$annotation.rrna.interval",
            },
            1 #dataflow id
        ]
    ]
);

done_testing();
