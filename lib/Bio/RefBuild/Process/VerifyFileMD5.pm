package Bio::RefBuild::Process::VerifyFileMD5;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::Process');

use autodie;
use Digest::MD5;

sub fetch_input {
    my ($self) = @_;

    my $file     = $self->param_required('file');
    my $md5_file = $self->param_required('md5_file');

    my $expected_md5;
    open( my $fh, '<', $md5_file );
    while (<$fh>) {
        if ($expected_md5) {

            #throw, multiple lines found
        }
        chomp;
        my ($md5) = split /\s/;
        $expected_md5 = $md5;
    }
    $self->param( 'expected_md5', $expected_md5 );
}

sub run {
    my $ctx = Digest::MD5->new;

    open( my $fh, '<', $self->param_required('file') );
    
    $ctx->addfile($file_handle);
    
    my $md5 = $ctx->digest;
    
    close($fh);
    
    $self->param( 'actual_md5', $md5 );


}

sub write_output {

}

1;
