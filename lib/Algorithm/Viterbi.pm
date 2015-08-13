package Algorithm::Viterbi;

use Mouse;
use Heap::Priority;

has 'lattice' => (
    is => 'rw',
    isa => 'HashRef[HashRef[Num]]'
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

has 'back_link' => (
    is => 'rw'
    );

has 'CRF' => (
    is => 'rw',
    isa => 'Algorithm::CRF',
    required => 1
    );

sub BUILD {
    my $self = shift;
    $self->{CRF}->{psi_cache} = undef;
    $self->{_labels} = $self->{CRF}->{_labels};
    $self->_construct_lattice();
}

sub _construct_lattice {
    my $self = shift;

    for(my $current_pos = 1; $current_pos < @{ $self->{_labels} }; $current_pos++){
	my $prev_pos = $current_pos - 1;
	foreach my $current_label (@{ $self->{_labels}->[$current_pos] }) {
	    if(!exists($self->{lattice}->{$current_pos}->{$current_label})){
		$self->{lattice}->{$current_pos}->{$current_label} = 0;
	    }

	    foreach my $prev_label (@{ $self->{_labels}->[$prev_pos] }) {
		if(!exists($self->{lattice}->{$prev_pos}->{$prev_label})){
		    $self->{lattice}->{$prev_pos}->{$prev_label} = 0;
		}

		my $tmp;
		if($self->{lattice}->{$current_pos}->{$current_label}
		   < ($tmp = $self->{lattice}->{$prev_pos}->{$prev_label}
		      + $self->compute_cost($current_label,$prev_label,$current_pos))){
		    $self->{lattice}->{$current_pos}->{$current_label}
		    = $tmp;
		    $self->{back_link}->{$current_pos}->{$current_label}
		    = {pos => $prev_pos, label => $prev_label};
		}
	    }
	}
    }
}

sub compute_best_path {
    my $self = shift;

    my $init_pos = scalar @{ $self->{_labels} } - 1;
    my $init_heuristic = $self->{lattice}->{$init_pos}->{chr(0x1f)};
    my $que = Heap::Priority->new();
    $que->fifo();
    $que->highest_first();

    my $init_state = { pos => $init_pos, 
		       label => chr(0x1f),
		       heuristic => $init_heuristic
    };
    $que->add($init_state,$init_heuristic);

    my $result = [];
    while($que->count() > 0){
	my $state = $que->pop();
	push @{ $result }, $state->{label};
	last if($state->{pos} == 0);

	my $back = $self->{back_link}->{ $state->{pos} }->{ $state->{label} };
	my $heuristic = $self->{lattice}->{ $state->{pos} }->{ $state->{label} };
	my $next_state = {
	    pos => $back->{pos},
	    label => $back->{label},
	    heuristic => $heuristic
	};
	$que->add($next_state,$heuristic);
    }
    @{ $result } = reverse(@{ $result });
    return $result;
}

sub compute_cost {
    my ($self,$current_label,$prev_label,$current_pos) = @_;
    return _dot($self->{CRF}->{weight},
		$self->{CRF}->compute_phi($self->{doc},$current_label,$prev_label,$current_pos));
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
