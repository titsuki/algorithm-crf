package Algorithm::CRF::Doc;

use Mouse;

has 'observed_sequence' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub{ [] }
    );

has 'labeled_sequence' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub{ [] }
    );

1;
