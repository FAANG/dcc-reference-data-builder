package Bio::RefBuild::Process::FilterGtfForExonsProcess;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

use autodie;
use Bio::RefBuild::Util::FilterGtfForExons;

sub fetch_input {
    my ($self) = @_;

    my $gtf     = $self->param_required('gtf');
    my $gtf_out = $self->param_required('exon_filtered_gtf');

}

sub run {
    my ($self) = @_;

    $self->dbc
      and $self->dbc->disconnect_when_inactive(1)
      ;    # release this connection for the duration of task

    my $gtf_fh;
    my $gtf     = $self->param_required('gtf');
    my $gtf_out = $self->param_required('exon_filtered_gtf');

    if ( $gtf =~ m/\.gz$/ ) {
        open( my $gtf_fh, '-|', 'gzip', '-dc', $gtf );
    }
    else {
        open( $gtf_fh, '<', $gtf );
    }
    open( my $gtf_out_fh, '>', $gtf_out );

    my $filter = Bio::RefBuild::Util::FilterGtfForExons->new(
        in_fh  => $gtf_fh,
        out_fh => $gtf_out_fh,
    );

    $filter->$filter();

    close $gtf_fh;
    close $gtf_out_fh;
}

1;
