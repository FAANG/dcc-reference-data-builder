package Bio::RefBuild::Util::GtfToRrnaInterval;

use strict;
use Moose;

has 'in_fh'        => ( is => 'rw', isa => 'FileHandle' );
has 'out_fh'       => ( is => 'rw', isa => 'FileHandle' );
has 'dict_fh' => ( is => 'rw', isa => 'FileHandle' );

#based on the gists here: https://www.biostars.org/p/67079/
sub convert {
    my ($self)  = @_;
    
    my $in_fh   = $self->in_fh();
    my $out_fh  = $self->out_fh();
    my $dict_fh = $self->dict_fh();

    while (<$dict_fh>) {
        print $out_fh $_;
    }

    while (<$in_fh>) {
        chomp;
        my @gtf = split /\t/;
          if ( $gtf[2]
            && $gtf[2] eq 'transcript'
            && $gtf[8]
            && $gtf[8] =~ m/gene_(bio)?type "rRNA"/ )
        {
            if ( $gtf[8] =~ /transcript_id "([^"]+)"/ ) {
                print $out_fh join( "\t", @gtf[ 0, 3, 4, 6 ], $1 ) . $/;
            }
        }
    }
}

1;
