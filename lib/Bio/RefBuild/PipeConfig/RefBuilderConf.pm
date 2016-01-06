package Bio::RefBuild::PipeConfig::RefBuilderConf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');

sub pipeline_wide_parameters {
    my ($self) = @_;
    return {
        %{ $self->SUPER::pipeline_wide_parameters },

        #required executables
        samtools                  => $self->o('samtools'),
        bowtie1_dir               => $self->o('bowtie1_dir'),
        bowtie2_dir               => $self->o('bowtie2_dir'),
        bedGraphToBigWig          => $self->o('bedGraphToBigWig'),
        rsem_dir                  => $self->o('rsem_dir'),
        picard                    => $self->o('picard'),
        java                      => $self->o('java'),
        bedtools                  => $self->o('bedtools'),
        bwa                       => $self->o('bwa'),
        star                      => $self->o('star'),
        gtfToGenePred             => $self->o('gtfToGenePred'),
        bismark_dir               => $self->o('bismark_dir'),
        output_root               => $self->o('output_root'),
        assembly_index_programs   => $self->o('assembly_index_programs'),
        annotation_index_programs => $self->o('annotation_index_programs'),
        wiggletools               => $self->o('wiggletools'),
        cram_seq_cache_populate_script =>
          $self->o('cram_seq_cache_populate_script'),
        cram_cache_root        => $self->o('cram_cache_root'),
        cram_cache_num_subdirs => $self->o('cram_cache_num_subdirs'),
    };
}

sub default_options {
    my ($self) = @_;
    return {
        %{ $self->SUPER::default_options() },
        assembly_index_programs   => [qw(bismark bwa bowtie1 bowtie2 star)],
        annotation_index_programs => [qw(rsem rsem_polya star)],
        pipeline_name             => 'ref_builder',
        lsf_std_param             => '',
        cram_cache_num_subdirs    => 2,
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
    dir_index_bismark
    dir_index_bowtie1
    dir_index_bowtie2
    dir_index_bwa
    dir_index_star

    manifest
    assembly_base_name
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

sub _pipeline_analyses_overall_control {
    my ($self) = @_;
    return (
        {
            -logic_name => 'start_all',
            -module     => 'Bio::RefBuild::Process::RefBuilderPreFlightChecks',
            -rc_name    => 'default',
            -parameters => {
                do_assembly   => 1,
                do_annotation => 1,
            },
            -flow_into => {
                '1->A' => ['count_fasta_lines'],
                'A->1' => ['post_assembly_steps'],
            }
        },
        {
            -logic_name => 'start_assembly',
            -module     => 'Bio::RefBuild::Process::RefBuilderPreFlightChecks',
            -rc_name    => 'default',
            -parameters => {
                do_assembly   => 1,
                do_annotation => 0,
            },
            -flow_into => ['count_fasta_lines'],
        },
        {
            -logic_name => 'start_annotation',
            -module     => 'Bio::RefBuild::Process::RefBuilderPreFlightChecks',
            -rc_name    => 'default',
            -parameters => {
                do_assembly   => 0,
                do_annotation => 1,

            },
            -flow_into => ['count_annotation_lines'],
        },
        {
            -logic_name => 'start_mappability',
            -module     => 'Bio::RefBuild::Process::RefBuilderPreFlightChecks',
            -rc_name    => 'default',
            -parameters => {
                do_assembly   => 0,
                do_annotation => 0,
            },
            -flow_into => ['kmer_factory'],
        },
        {
            -logic_name => 'start_manifest',
            -module     => 'Bio::RefBuild::Process::RefBuilderPreFlightChecks',
            -rc_name    => 'default',
            -parameters => {
                do_assembly   => 0,
                do_annotation => 0,
            },
            -flow_into => ['write_manifest'],
        },
        {
            -logic_name  => 'post_assembly_steps',
            -module      => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -meadow_type => 'LOCAL',
            -flow_into   => {
                '1->A' => [ 'count_annotation_lines', 'kmer_factory' ],
                'A->1' => ['write_manifest'],
            }
        },
    );
}

sub _pipeline_analyses_mappability_tasks {
    my ($self) = @_;
    return (
        {
            -logic_name => 'kmer_factory',
            -rc_name    => 'default',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                inputlist       => '#expr( [eval(#kmer_sizes#)] )expr#',
                fan_branch_code => 1,
                column_names    => ['kmer_size'],
            },
            -flow_into => {
                '1' => {
                    'kmer_output_dir' => {
                        kmer_size    => '#kmer_size#',
                        kmer_out_dir => '#dir_mappability#/k#kmer_size#',
                        name         => '#assembly_name#.k#kmer_size#',
                    },
                },
            },
        },
        {
            -logic_name => 'kmer_output_dir',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters => { cmd => 'mkdir -p #kmer_out_dir#', },
            -rc_name    => 'default',
            -flow_into  => {
                '1->A' => ['mappa_fasta_allocation'],
                'A->1' => {
                    'bam_merge' => {
                        bigwig   => '#kmer_out_dir#/#name#.bw',
                        bedgraph => '#kmer_out_dir#/#name#.bg',
                        bam      => '#kmer_out_dir#/#name#.bam',
                        mappable_pos_bedgraph =>
                          '#kmer_out_dir#/#name#.mappable_pos.bg',
                        mappable_pos_bigwig =>
                          '#kmer_out_dir#/#name#.mappable_pos.bw',
                    }
                },
            }
        },
        {
            -logic_name => 'mappa_fasta_allocation',
            -module     => 'Bio::GenomeSignalTracks::Process::DivideFastaByFai',
            -parameters => {
                fai               => '#fai#',
                target_base_pairs => 20_000_000,
                fan_branch_code   => 2,
            },
            -rc_name   => 'default',
            -flow_into => {
                '2' => {
                    'fasta_kmers_factory' => {
                        fasta_file       => '#fasta#',
                        seq_start_pos    => '#seq_start_pos#',
                        num_seqs_to_read => '#num_seqs_to_read#',
                        first_seq_name   => '#first_seq_name#',
                        kmer_size        => '#kmer_size#',
                    }
                },
            }
        },
        {
            -logic_name => 'fasta_kmers_factory',
            -module => 'Bio::GenomeSignalTracks::Process::FastaKmerSplitter',
            -parameters => {
                gzip         => 1,
                split_limit  => 250_000_000,
                output_dir   => '#kmer_out_dir#',
                no_ambiguity => 1,
            },
            -rc_name   => '2Gb_job',
            -flow_into => {
                2 => {
                    'mappa_bowtie' =>
                      { bam => '#kmer_file#.bam', kmer_file => '#kmer_file#' }
                }
            },
        },
        {
            -logic_name => 'mappa_bowtie',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -parameters => {
                cmd =>
'gunzip -c #kmer_file# | #bowtie1_dir#/bowtie -v 0 -k 1 -m 1 -f -S #dir_index_bowtie1#/#assembly_base_name# - | #samtools# view -SbF4 - > #bam#',
                expected_file => '#bam#'
            },
            -rc_name   => '2Gb_job',
            -flow_into => {
                1 => {
                    'mappa_sort_bam' => { 'bam'  => '#bam#' },
                    'rm_file'        => { 'file' => '#kmer_file#' },

                }
            },
        },
        {
            -logic_name => 'mappa_sort_bam',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -parameters => {
                sorted_bam => '#bam#.sorted.bam',
                cmd =>
                  '#samtools# sort -O bam -o #sorted_bam# -T #bam#.tmp #bam#',
                expected_file => '#sorted_bam#',
            },
            -rc_name   => '2Gb_job',
            -flow_into => {
                1 => {
                    ':////accu?sorted_bam=[]' => {},
                    'rm_file'                 => { file => '#bam#' },
                }
            },
        },
        {
            -logic_name        => 'rm_file',
            -module            => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters        => { cmd => 'rm -f #file#', },
            -analysis_capacity => 1,
        },

        {
            -logic_name => 'bam_merge',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -rc_name    => '2Gb_job',
            -parameters => {
                cmd =>
'#samtools# merge -f #bam# #expr(join(" ",@{#sorted_bam#}))expr#',
                expected_file => '#bam#',
            },
            -flow_into => {
                1 => {
                    'genome_cov_bg' => { bam => '#bam#', },
                    'rm_file' =>
                      { 'file' => '#expr(join(" ",@{#sorted_bam#}))expr#' }
                }
            }
        },
        {
            -logic_name => 'genome_cov_bg',
            -rc_name    => '3Gb_job',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -parameters => {
                scaling_factor => '#expr( 1/#kmer_size# )expr#',
                cmd =>
'#bedtools# genomecov -ibam #bam# -bg -scale #scaling_factor# > #bedgraph#',
                expected_file => '#bedgraph#',
            },
            -flow_into => {
                1 => {
                    'mappable_pos'     => {},
                    'bedGraphToBigWig' => { bedgraph => '#bedgraph#', },

                }
            }
        },
        {
            -logic_name => 'mappable_pos',
            -rc_name    => '400Mb_job',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -parameters => {
                cmd =>
'#samtools# view #bam# | awk \'BEGIN{FS="\t";OFS=FS}{print $3,$4-1,$4,1}\' | #wiggletools# write_bg - - > #mappable_pos_bedgraph#',
                expected_file => '#mappable_pos_bedgraph#',
            },
            -flow_into => {
                1 => {

                    'rm_file'         => { file => '#bam#' },
                    'mappable_pos_bw' => {},

                }
            }
        },
        {
            -logic_name => 'mappable_pos_bw',
            -rc_name    => '2Gb_job',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -parameters => {
                cmd =>
'#bedGraphToBigWig# #mappable_pos_bedgraph# #chrom_sizes# #mappable_pos_bigwig#',
                expected_file => '#mappable_pos_bigwig#',
            },
            -flow_into =>
              { 1 => { 'rm_file' => { file => '#mappable_pos_bedgraph#' }, } }
        },
        {
            -logic_name => 'bedGraphToBigWig',
            -rc_name    => '2Gb_job',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -parameters => {
                cmd => '#bedGraphToBigWig# #bedgraph# #chrom_sizes# #bigwig# ',
                expected_file => '#bigwig#',
            },
            -flow_into => {
                1 => {

                    rm_file               => { file   => '#bedgraph#' },
                    mappa_auc             => { bigwig => '#bigwig#' },
                    mappa_low_mappability => { bigwig => '#bigwig#' },
                    mappa_histogram       => { bigwig => '#bigwig#' },
                },

            }
        },
        {
            -logic_name => 'mappa_auc',
            -rc_name    => 'default',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -parameters => {
                auc           => '#kmer_out_dir#/#name#.auc',
                cmd           => '#wiggletools# AUC #bigwig# > #auc#',
                expected_file => '#auc#',
            },
        },
        {
            -logic_name => 'mappa_low_mappability',
            -rc_name    => 'default',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -parameters => {
                low_mappability_threshold => 0.25,
                lm =>
'#kmer_out_dir#/#name#.low_mappability.lt#low_mappability_threshold#.bed',
                cmd =>
'#wiggletools# write_bg - lt #low_mappability_threshold# #bigwig# | cut -f1-3 > #lm#',
                expected_file => '#lm#',
            },
        },
        {
            -logic_name => 'mappa_histogram',
            -rc_name    => 'default',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -parameters => {
                num_of_hist_bins => 10,
                histogram        => '#kmer_out_dir#/#name#.histogram',
                cmd =>
'echo "mappability	#name#" > #histogram# ; #wiggletools# histogram - #num_of_hist_bins# default 0 #bigwig# >> #histogram#',
                expected_file           => '#histogram#',
                expected_file_num_lines => 11,
            },
        },
    );
}

sub _pipeline_analyses_assembly {
    my ($self) = @_;
    return (
        {
            -logic_name => 'count_fasta_lines',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                inputcmd        => 'gunzip -c #fasta_file#  | wc -l',
                fan_branch_code => 1,
                column_names    => ['fasta_line_count'],
            },
            -flow_into => ['count_fasta_seq'],
        },
        {
            -logic_name => 'count_fasta_seq',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                inputcmd        => 'gunzip -c #fasta_file#  | grep \> | wc -l',
                fan_branch_code => 1,
                column_names    => ['fasta_seq_count'],
            },
            -flow_into => ['unzip_fasta'],
        },
        {
            -logic_name => 'unzip_fasta',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -rc_name    => 'default',
            -parameters => {
                cmd                     => 'gunzip -c #fasta_file# > #fasta#',
                expected_file           => '#fasta#',
                expected_file_num_lines => '#fasta_line_count#',
            },
            -flow_into => [
                'picard_dict',       'samtools_fai',
                'bowtie1_index',     'bowtie2_index',
                'pre_bismark_index', 'populate_cram_cache',
                'bwa_index',         'star_index_prep'
            ],
        },
        {
            -logic_name => 'populate_cram_cache',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '1Gb_job',
            -parameters => {
                cmd =>
'#cram_seq_cache_populate_script# -root #cram_cache_root# -subdirs #cram_cache_num_subdirs# #fasta#'
            },
        },
        {
            -logic_name => 'samtools_fai',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -rc_name    => 'default',
            -parameters => {
                cmd                     => '#samtools# faidx #fasta#',
                expected_file           => '#fai#',
                expected_file_num_lines => '#fasta_seq_count#',
            },
            -flow_into => [ 'chrom_sizes', ],
        },
        {
            -logic_name => 'chrom_sizes',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -rc_name    => 'default',
            -parameters => {
                cmd                     => 'cut -f1,2 #fai# > #chrom_sizes#',
                expected_file           => '#chrom_sizes#',
                expected_file_num_lines => '#fasta_seq_count#',
            },
        },
        {
            -logic_name => 'picard_dict',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -rc_name    => '4Gb_job',
            -parameters => {
                cmd =>
'touch #dict#; rm #dict# ; #java# -Xmx4G -jar #picard# CreateSequenceDictionary REFERENCE=#fasta# OUTPUT=#dict# GENOME_ASSEMBLY="#assembly_name#" SPECIES="#species_name#" URI="#fasta_uri#" TMP_DIR=#dir_base#',
                expected_file           => '#dict#',
                expected_file_num_lines => '#expr(#fasta_seq_count#+1)expr#'
            },

        },
        {
            -logic_name => 'bwa_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '5Gb_job',
            -parameters => {
                cmd =>
                  '#bwa# index -p #dir_index_bwa#/#assembly_base_name# #fasta#',
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
            -flow_into => ['bismark_index']
        },
        {
            -logic_name => 'bismark_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '12Gb_job',
            -parameters => {
                cmd =>
'#bismark_dir#/bismark_genome_preparation --path_to_bowtie #bowtie1_dir# --yes_to_all #dir_index_bismark#',
            },
        },
        {
            -logic_name => 'star_index_prep',
            -module =>
              'Bio::RefBuild::Process::StarGenomeGenerateParamsProcess',
            -rc_name    => 'default',
            -parameters => { fasta_file => '#fasta#' },
            -flow_into   => ['star_index'],
        },
        {
            -logic_name => 'star_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'star_job',
            -parameters => {
                cmd =>
'#star# --runMode genomeGenerate --runThreadN 4 --genomeDir #dir_index_star# --genomeFastaFiles #fasta# --genomeChrBinNbits #genomeChrBinNbuts# --genomeSAindexNbases #genomeSAindexNbases#',
            },
        },
    );
}

sub _pipeline_analyses_annotation {
    my ($self) = @_;
    return (
        {
            -logic_name => 'count_annotation_lines',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                inputcmd        => 'gunzip -c #gtf_file# | wc -l',
                fan_branch_code => 1,
                column_names    => ['annotation_line_count'],
            },
            -flow_into => [ 'cp_annotation', 'unzip_annotation' ],
        },
        {
            -logic_name => 'cp_annotation',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -rc_name    => 'default',
            -parameters => {
                cmd                     => 'cp #gtf_file# #gtf_gz#',
                expected_file           => '#gtf_gz#',
                expected_file_num_lines => '#annotation_line_count#'
            },
            -flow_into => ['ref_flat'],
        },

        {
            -logic_name => 'unzip_annotation',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -rc_name    => 'default',
            -parameters => {
                cmd                     => 'gunzip -c #gtf_file# > #gtf#',
                expected_file           => '#gtf#',
                expected_file_num_lines => '#annotation_line_count#'
            },
            -flow_into => [
                'gtf_to_beds', 'rrna_interval',
                'filter_gtf',

            ],
        },
        {
            -logic_name => 'filter_gtf',
            -module     => 'Bio::RefBuild::Process::FilterGtfForExonsProcess',
            -rc_name    => 'default',
            -parameters => {
                gtf               => '#gtf#',
                exon_filtered_gtf => '#exon_filtered_gtf#',
            },
            -flow_into =>
              [ 'rsem_index', 'rsem_polya_index', 'star_guided_index_prep' ],
        },
        {
            -logic_name => 'gtf_to_beds',
            -module     => 'Bio::RefBuild::Process::GtfToBedsProcess',
            -rc_name    => '200Mb_job',
            -parameters => {
                gtf                  => '#gtf#',
                dir_annotation_base  => '#dir_annotation_base#',
                annotation_base_name => '#annotation_base_name#',
            },
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
        { # adapted from https://gist.github.com/igordot/4467f1b02234ff864e61 ref flat from gtf
            -logic_name => 'ref_flat',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '1Gb_job',
            -parameters => {
                cmd =>
'#gtfToGenePred# -genePredExt -geneNameAsName2 #gtf# /dev/stdout | awk \'BEGIN{OFS="\t";FS="\t"}{print $12,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10}\' | gzip -c > #ref_flat#',
            },
        },
        {
            -logic_name => 'rsem_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '2Gb_job',
            -parameters => {
                cmd =>
'#rsem_dir#/rsem-prepare-reference -q --gtf #exon_filtered_gtf# --bowtie --bowtie-path #bowtie1_dir# --bowtie2 --bowtie2-path #bowtie2_dir# #fasta# #dir_annot_index_rsem#/#annotation_base_name#'
            },
        },
        {
            -logic_name => 'rsem_polya_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => '2Gb_job',
            -parameters => {
                cmd =>
'#rsem_dir#/rsem-prepare-reference -q --polyA --gtf #exon_filtered_gtf# --bowtie --bowtie-path #bowtie1_dir# --bowtie2 --bowtie2-path #bowtie2_dir# #fasta# #dir_annot_index_rsem_polya#/#annotation_base_name#_polya'
            },
        },
        {
            -logic_name => 'star_guided_index_prep',
            -module =>
              'Bio::RefBuild::Process::StarGenomeGenerateParamsProcess',
            -rc_name    => 'default',
            -parameters => { fasta_file => '#fasta#' },
            -flow_into   => ['star_guided_index'],
        },
        {
            -logic_name => 'star_guided_index',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
            -rc_name    => 'star_job',
            -parameters => {
                cmd =>
'#star# --runMode genomeGenerate --runThreadN 4 --genomeDir #dir_annot_index_star# --genomeFastaFiles #fasta# --sjdbGTFfile #exon_filtered_gtf# --genomeChrBinNbits #genomeChrBinNbuts# --genomeSAindexNbases #genomeSAindexNbases#',
            },
        },
    );
}

sub _pipeline_analyses_manifest {
    my ($self) = @_;
    return (
        {
            -logic_name => 'write_manifest',
            -module     => 'Bio::RefBuild::Process::CautiousSystemCommand',
            -rc_name    => 'default',
            -parameters => {
                cmd =>
'find #dir_base# -type f -printf \'%p\t%s\t\' -execdir sh -c \'md5sum "{}" | sed s/\ .*//\' \; > #manifest#',
                expected_file => '#manifest#',
            },
        },
    );
}

sub pipeline_analyses {
    my ($self) = @_;
    return [
        $self->_pipeline_analyses_overall_control(),
        $self->_pipeline_analyses_assembly(),
        $self->_pipeline_analyses_mappability_tasks(),
        $self->_pipeline_analyses_annotation(),
        $self->_pipeline_analyses_manifest(),
    ];
}

sub resource_classes {
    my ($self) = @_;

    my $lsf_queue_name = $self->o('lsf_queue_name');
    my $lsf_std_param  = $self->o('lsf_std_param');

    my $gb          = 1024;
    my %name_to_mem = (
        'default'   => 100,
        '200Mb_job' => 200,
        '400Mb_job' => 400,
        '1Gb_job'   => $gb,
        '2Gb_job'   => 2 * $gb,
        '3Gb_job'   => 3 * $gb,
        '4Gb_job'   => 4 * $gb,
        '5Gb_job'   => 5 * $gb,
        '6Gb_job'   => 6 * $gb,
        '7Gb_job'   => 7 * $gb,
        '10Gb_job'  => 10 * $gb,
        '12Gb_job'  => 12 * $gb,
    );

    my %resources = (
        'star_job' => {
            'LSF' =>
"-M38000 -q $lsf_queue_name -n4 -R\"span[hosts=1]  select[mem>38000] rusage[mem=38000]\" $lsf_std_param",
        },
    );

    for my $n ( sort keys %name_to_mem ) {
        my $m = $name_to_mem{$n};
        $resources{$n} = {
            LSF =>
"-M$m -q $lsf_queue_name -R\"span[hosts=1]  select[mem>$m] rusage[mem=$m]\" $lsf_std_param",

        };
    }

    return \%resources;
}

sub hive_meta_table {
    my ($self) = @_;
    return { %{ $self->SUPER::hive_meta_table }, 'hive_use_param_stack' => 1, };
}
1;
