package Bio::RefBuild::Process::CreateDirs;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

use autodie;
use File::Path qw(make_path);

sub fetch_input {
    my ($self) = @_;

    my $root_output_dir = $self->param_required('output_root');
    my $index_programs  = $self->param_required('index_programs');
    
    my $assembly_name   = $self->param_required('assembly_name');
#    my $assembly_name   = $self->param_required('annotation_name');
    
}

sub run {
    my ($self)          = @_;
    my $root_output_dir = $self->param_required('output_root');
    my $assembly_name   = $self->param_required('assembly_name');

    my %dirs_created;

    my @dirs = qw(fasta support mappability annotation);

    $dirs_created{"dir_base"} = "$root_output_dir/$assembly_name";

    for my $dir (@dirs) {
        my $target = "$root_output_dir/$assembly_name/$dir";
        make_path($target);
        $dirs_created{"dir_$dir"} = $target;
    }

    my $index_programs = $self->param_required('index_programs');

    for my $index_prog (@$index_programs) {
        my $target = "$root_output_dir/$assembly_name/index/$index_prog";
        make_path($target);
        $dirs_created{"dir_index_$index_prog"} = $target;
    }

    $self->param( 'dirs_created', \%dirs_created );
}

sub write_output {
    my ($self) = @_;
    $self->dataflow_output_id( $self->param('dirs_created'), 1 );
}

1;
