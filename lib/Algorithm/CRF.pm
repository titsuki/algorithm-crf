package Algorithm::CRF;

use Mouse;
use Data::Dumper;

has 'docs' => (
    is => 'rw',
    isa => 'ArrayRef[Algorithm::CRF::Doc]',
    default => sub{ [] }
    );

has 'weight' => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    default => sub{ [] }
    );

has 'feature_functions' => (
    is => 'rw',
    isa => 'ArrayRef[CodeRef]'
    );

has 'alpha_cache' => (
    is => 'rw'
    );

has 'beta_cache' => (
    is => 'rw'
    );

has 'T' => (
    is => 'rw',
    isa => 'Num'
    );

has 'ratio' => (
    is => 'rw',
    isa => 'Num',
    default => 0.1
    );

has 'psi_cache' => (
    is => 'rw',
    );

has '_labels' => (
    is => 'rw',
    isa => 'ArrayRef[ArrayRef[Str]]'
    );

has 'labels' => (
    is => 'rw',
    isa => 'ArrayRef[Str]'
    );


sub BUILD {
    my $self = shift;
    my @dummy = map { 0 } @{ $self->{feature_functions} };
    $self->{weight} = [@dummy];
    $self->{T} = scalar @{ $self->{docs}->[0]->{observed_sequence} };
    $self->{alpha_cache}->{chr(0x1e)}->{0} = 1.0;

    $self->{_labels}->[0] = [chr(0x1e)];
    for(my $i = 1; $i < @{ $self->{docs}->[0]->{labeled_sequence} }; $i++){
	$self->{_labels}->[$i] = $self->{labels};
    }
    $self->{beta_cache}->{chr(0x1f)}->{scalar @{ $self->{docs}->[0]->{labeled_sequence}} - 1} = 1.0;
    $self->{_labels}->[scalar @{ $self->{docs}->[0]->{labeled_sequence}} - 1] = [chr(0x1f)];
}

sub train {
    my $self = shift;
    for(my $i = 0; $i < 1; $i++){
	my $delta = $self->compute_delta();
	for(my $j = 0; $j < @{ $delta }; $j++){
	    $delta->[$j] *= 0.1;
	}
	$self->{weight} = $delta;
	print Dumper($self->{weight});
    }
}

sub compute_delta {
    my $self = shift;
    my @dummy = map { 0 } @{ $self->{feature_functions} };
    my $front = [@dummy]; 

    foreach my $doc (@{ $self->{docs} }){
	for(my $t = 1; $t < @{ $doc->{labeled_sequence} }; $t++){
	    $front = _add($front,
			  $self->compute_phi($doc->{observed_sequence},
					     $doc->{labeled_sequence}->[$t],
					     $doc->{labeled_sequence}->[$t - 1]));
	    my $rear = [@dummy]; 
	    foreach my $doc_y (@{ $self->{docs} }){
		my $current_label = $doc_y->{labeled_sequence}->[$t];
		my $prev_label = $doc_y->{labeled_sequence}->[$t - 1];
		my $co = 1.0 / $self->compute_Z()
		    * $self->compute_psi($doc,$current_label,$prev_label,$t)
		    * $self->compute_alpha($doc,$current_label,$t)
		    * $self->compute_beta($doc,$current_label,$t);
		my $tmp_vector = $self->compute_phi($doc->{observed_sequence},$current_label,$prev_label); 
		for(my $vector_i = 0; $vector_i < @{ $tmp_vector }; $vector_i++){
		    $tmp_vector->[$vector_i] *= $co;
		}
		$rear = _add($rear,$tmp_vector);
	    }

	    $front = _sub($front,$rear);
	}
    }
    return $front;
}

sub compute_alpha {
    my ($self,$doc,$current_label,$t) = @_;

    if(exists($self->{alpha_cache}->{$current_label}->{$t})){
	return $self->{alpha_cache}->{$current_label}->{$t};
    }

    foreach my $prev_label (@{ $self->{_labels}->[$t - 1] }){
	$self->{alpha_cache}->{$current_label}->{$t} += 
	    $self->compute_psi($doc,$current_label, $prev_label, $t)
	    * $self->compute_alpha($doc,$prev_label, $t - 1);
    }
    return $self->{alpha_cache}->{$current_label}->{$t};
}

sub compute_beta {
    my ($self,$doc,$current_label,$t) = @_;

    if($t + 1 > @{ $doc->{labeled_sequence} }){
	return 0;
    }

    if(exists($self->{beta_cache}->{$current_label}->{$t})){
	return $self->{beta_cache}->{$current_label}->{$t};
    }

    foreach my $next_label (@{ $self->{_labels}->[$t + 1] }){
	$self->{beta_cache}->{$current_label}->{$t} += 
	    $self->compute_psi($doc,$next_label, $current_label, $t + 1)
	    * $self->compute_beta($doc,$next_label, $t + 1);
    }
    return $self->{beta_cache}->{$current_label}->{$t};
}

sub compute_psi {
    my ($self,$observed_sequence,$current_label,$prev_label,$t) = @_;
    if(exists($self->{psi_cache}->{$current_label}->{$prev_label}->{$t})){
	return $self->{psi_cache}->{$current_label}->{$prev_label}->{$t};
    }
    return ($self->{psi_cache}->{$current_label}->{$prev_label}->{$t}
	    = exp(_dot($self->{weight},$self->compute_phi($observed_sequence,$current_label,$prev_label,$t))));
}

sub compute_phi {
    my ($self,$observed_sequence,$current_label,$prev_label,$t) = @_;
    my $vector = [];
    foreach my $func (@{ $self->{feature_functions} }){
	push @{ $vector }, $func->($observed_sequence,$current_label,$prev_label,$t);
    }
    return $vector;
}

sub compute_Z {
    my $self = shift;
    return 1;
}

sub _dot {
    my ($vector1, $vector2) = @_;
    my $sum = 0;
    for(my $i = 0; $i < @{ $vector1 }; $i++){
	$sum += $vector1->[$i] * $vector2->[$i];
    }
    return $sum;
}

sub _add {
    my ($vector1, $vector2) = @_;
    my $merged = [];
    for(my $i = 0; $i < @{ $vector1 }; $i++){
	push @{ $merged }, $vector1->[$i] + $vector2->[$i];
    }
    return $merged;
}

sub _sub {
    my ($vector1, $vector2) = @_;
    my $merged = [];
    for(my $i = 0; $i < @{ $vector1 }; $i++){
	push @{ $merged }, $vector1->[$i] - $vector2->[$i];
    }
    return $merged;
}

1;
