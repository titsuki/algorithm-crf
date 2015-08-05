package Algorithm::CRF;

use Mouse;

has 'docs' => (
    is => 'rw',
    isa => 'ArrayRef[Algorithm::CRF::Doc]',
    default => sub{ [] }
    );

sub train {
    my $self = shift;
}

sub compute_alpha {
    my $self = shift;
}

sub compute_beta {
    my $self = shift;
}

sub compute_Z {
    my $self = shift;
}

1;
