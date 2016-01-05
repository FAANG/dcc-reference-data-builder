package Bio::RefBuild::Util::StarGenomeGenerateParams;

use Moose;
use List::Util qw(min);

has 'fasta_in_fh' => ( is => 'rw', isa => 'FileHandle' );

sub calculate_params {
    my ($self) = @_;
    my $in_fh = $self->fasta_in_fh();

    my $ref_count  = 0;
    my $base_count = 0;

    # parse the fasta for counts
    while ( my $line = <$in_fh> ) {
        if ( substr( $line, 0, 1 ) eq '>' ) {
            $ref_count++;
        }
        else {
            chomp $line;
            $base_count += length($line);
        }
    }

    #--genomeChrBinNbits
    my $genChrBinNbits =
      min( 18, round_to_int( log2( $base_count / $ref_count ) ) );

    #--genomeSAindexNbases
    my $genSAindexNbases = min( 14, round_to_int( log2($base_count) / 2 - 1 ) );

    return {
        ref_count           => $ref_count,
        base_count          => $base_count,
        genomeChrBinNbits   => $genChrBinNbits,
        genomeSAindexNbases => $genSAindexNbases,
    };
}

sub round_to_int {
    my ($n) = @_;

    return int( $n + 0.5 );
}

sub log2 {
    my ($n) = @_;

    return log($n) / log(2);
}
1;