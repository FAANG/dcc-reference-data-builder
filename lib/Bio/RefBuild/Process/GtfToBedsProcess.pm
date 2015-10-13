package Bio::RefBuild::Process::GtfToBedsProcess;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

use autodie;
use Bio::RefBuild::Util::GtfToBed;

sub fetch_input {
    my ($self) = @_;

    my $gtf                  = $self->param_required('gtf');
    my $dir_annotation_base  = $self->param_required('dir_annotation_base');
    my $annotation_base_name = $self->param_required('annotation_base_name');

}

sub run {
    my ($self) = @_;

    $self->dbc
      and $self->dbc->disconnect_when_inactive(1)
      ;    # release this connection for the duration of task

    my $gtf_fh;
    my $gtf                  = $self->param_required('gtf');
    my $dir_annotation_base  = $self->param_required('dir_annotation_base');
    my $annotation_base_name = $self->param_required('annotation_base_name');

    if ( $gtf =~ m/\.gz$/ ) {
        open( my $gtf_fh, '-|', 'gzip', '-dc', $gtf );
    }
    else {
        open( $gtf_fh, '<', $gtf );
    }

    my $converter = Bio::RefBuild::Util::GtfToBed->new(
        in_fh     => $gtf_fh,
        base_name => $annotation_base_name,
        out_dir   => $dir_annotation_base,
    );

    $converter->convert();

    close $gtf_fh;
}

1;