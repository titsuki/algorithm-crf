package Algorithm::Viterbi;

use Mouse;

has 'lattice' => (
    is => 'rw',
    );

has 'doc' => (
    is => 'rw',
    isa => 'Algorithm::CRF::Doc',
    required => 1
    );

has 'labels' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    required => 1
    );

has '_labels' => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[Str]]'
    );

has 'cache_table' => (
    is => 'rw',
    isa => 'HashRef[HashRef[Num]]',
    );

has 'CRF' => (
    is => 'rw',
    isa => 'Algorithm::CRF',
    required => 1
    );

sub BUILD {
    my $self = shift;
    $self->{CRF}->{psi_cache} = undef;
    $self->_init_labels();
}

sub construct_lattice {
    my $self = shift;

    for(my $current_pos = 0; $current_pos < @{ $self->{doc}->{observed_sequence} }; $current_pos++){
	my $prev_pos = $current_pos - 1;
	foreach my $prev_label (@{ $self->{_labels}->[$prev_pos] }) {
	    if(!exists($self->{cache_table}->{$prev_pos}->{$prev_label})){
		$self->{cache_table}->{$prev_pos}->{$prev_label} = 0;
	    }

	    foreach my $current_label (@{ $self->{_labels}->[$current_pos] }) {
		if(!exists($self->{cache_table}->{$current_pos}->{$current_label})){
		    $self->{cache_table}->{$current_pos}->{$current_label} = 0;
		}

		$self->{cache_table}->{$current_pos}->{$current_label}
		= _max($self->{cache_table}->{$current_pos}->{$current_label},
		      $self->{cache_table}->{$prev_pos}->{$prev_label}
		      + $self->compute_cost($current_label,$prev_label,$current_pos));
	    }
	}
    }
}

sub compute_cost {
    my ($self,$current_label,$prev_label,$current_pos) = @_;
    return _dot($self->{CRF}->{weight},$self->{CRF}->compute_phi($self->{doc},$current_label,$prev_label,$current_pos));
}

sub _init_labels{
    my $self = shift;

    # init each labels
    $self->{_labels} = [];
    push @{ $self->{_labels} }, [chr(0x1e)];
    for(my $t = 0; $t < scalar @{ $self->{doc}->{observed_sequence} }; $t++){
	push @{ $self->{_labels} }, $self->{labels};
    }
    push @{ $self->{_labels} }, [chr(0x1f)];
}

sub _dot {
    my ($vector1, $vector2) = @_;
    my $sum = 0;
    for(my $i = 0; $i < @{ $vector1 }; $i++){
	$sum += $vector1->[$i] * $vector2->[$i];
    }
    return $sum;
}

sub _max {
    my ($lhs,$rhs) = @_;
    return ($lhs < $rhs ? $rhs : $lhs);
}

1;
