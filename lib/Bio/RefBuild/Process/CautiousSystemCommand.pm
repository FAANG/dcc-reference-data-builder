package Bio::RefBuild::Process::CautiousSystemCommand;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::RunnableDB::SystemCmd');
use IPC::System::Simple qw(capture);

sub run {
    my ($self) = @_;

    $self->SUPER::run();

    #if there's a non-zero return value, there's already a problem
    return if ( $self->param('return_value') );

    my $file                    = $self->param_required('expected_file');
    my $expected_file_num_lines = $self->param('expected_file_num_lines');

    if ( !-e $file ) {
        die "Expected file to be created, but it doesn't exist: $file";
    }

    if ($expected_file_num_lines) {
        my $line_count = $self->line_count($file);
        if ( $line_count != $expected_file_num_lines ) {
            die
"Expected $file to contain $expected_file_num_lines lines, it contains $line_count";
        }
    }
}

sub line_count {
    my ( $self, $file ) = @_;

    my $cmd;

    if ( $file =~ /\.gz$/ ) {
        $cmd = "gunzip -c $file | wc -l";
    }
    else {
        $cmd = "wc -l $file";
    }

    my $count = capture($cmd);
    chomp $count;
    return $count;
}

1;
