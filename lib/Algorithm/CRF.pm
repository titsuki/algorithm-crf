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

has 'learning_rate' => (
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

has 'iter_limit' => (
    is => 'rw',
    isa => 'Int',
    default => 1
    );

has 'C' => (
    is => 'ro',
    isa => 'Num',
    default => 1
    );

sub BUILD {
    my $self = shift;
    my @dummy = map { 0 } @{ $self->{feature_functions} };
    $self->{weight} = [@dummy];

    for(my $doc_i = 0; $doc_i < @{ $self->{docs} }; $doc_i++){
	$self->{docs}->[$doc_i]->{id} = $doc_i;
    }
}

sub train {
    my $self = shift;
    for(my $i = 0; $i < $self->{iter_limit}; $i++){
	my $delta = $self->compute_delta();
	$delta = _multiply($self->{learning_rate},$delta);
	$self->{weight} = _add($self->{weight},$delta);
    }
}

sub _compute_cache {
    my ($self,$doc) = @_;

    # init each labels
    $self->{_labels} = [];
    $self->{_labels}->[0] = [chr(0x1e)];
    for(my $t = 1; $t < scalar @{ $doc->{labeled_sequence} } - 1; $t++){
	$self->{_labels}->[$t] = $self->{labels};
    }
    $self->{_labels}->[scalar @{ $doc->{labeled_sequence} } - 1] = [chr(0x1f)];
    
    # cache alpha/beta
    $self->{alpha_cache}->{$doc->{id}}->{chr(0x1e)}->{0} = 1.0;
    $self->{beta_cache}->{$doc->{id}}->{chr(0x1f)}->{scalar @{ $doc->{labeled_sequence} } - 1} = 1.0;

    for(my $t = 1; $t < @{ $doc->{labeled_sequence} }; $t++){
	my $current_label = $doc->{labeled_sequence}->[$t];
	$self->compute_alpha($doc,$current_label,$t);
    }
    
    for(my $t = @{ $doc->{labeled_sequence} } - 2; $t >= 0; $t--){
	my $current_label = $doc->{labeled_sequence}->[$t];
	$self->compute_beta($doc,$current_label,$t);
    }
}

sub compute_delta {
    my $self = shift;
    my @dummy = map { 0 } @{ $self->{feature_functions} };
    my $front = [@dummy]; 

    foreach my $doc (@{ $self->{docs} }){
	$self->_compute_cache($doc);

	for(my $t = 1; $t < @{ $doc->{labeled_sequence} }; $t++){
	    $front = _add($front,
			  $self->compute_phi($doc,
					     $doc->{labeled_sequence}->[$t],
					     $doc->{labeled_sequence}->[$t - 1],$t));
	    my $rear = [@dummy]; 
	    
	    foreach my $current_label (@{ $self->{_labels}->[$t] }){
		foreach my $prev_label (@{ $self->{_labels}->[$t - 1] }){
		    my $marginal_probability = $self->compute_marginal_probability($doc,$current_label,$prev_label,$t);
		    $rear = _add($rear,_multiply($marginal_probability,$self->compute_phi($doc,$current_label,$prev_label,$t)));
		}
	    }
	    
	    $front = _sub($front,$rear);
	}
    }
    $front = _sub($front,_multiply($self->{C},$self->{weight}));
    return $front;
}

sub compute_alpha {
    my ($self,$doc,$current_label,$t) = @_;

    if($t < 0){
	return 0;
    }

    if(exists($self->{alpha_cache}->{$doc->{id}}->{$current_label}->{$t})){
	return $self->{alpha_cache}->{$doc->{id}}->{$current_label}->{$t};
    }

    foreach my $prev_label (@{ $self->{_labels}->[$t - 1] }){
	$self->{alpha_cache}->{$doc->{id}}->{$current_label}->{$t} += 
	    $self->compute_psi($doc,$current_label, $prev_label, $t)
	    * $self->compute_alpha($doc,$prev_label, $t - 1);
    }
    return $self->{alpha_cache}->{$doc->{id}}->{$current_label}->{$t};
}

sub compute_beta {
    my ($self,$doc,$current_label,$t) = @_;

    if($t + 1 > @{ $doc->{labeled_sequence} }){
	return 0;
    }

    if(exists($self->{beta_cache}->{$doc->{id}}->{$current_label}->{$t})){
	return $self->{beta_cache}->{$doc->{id}}->{$current_label}->{$t};
    }

    foreach my $next_label (@{ $self->{_labels}->[$t + 1] }){
	$self->{beta_cache}->{$doc->{id}}->{$current_label}->{$t} += 
	    $self->compute_psi($doc,$next_label, $current_label, $t + 1)
	    * $self->compute_beta($doc,$next_label, $t + 1);
    }
    return $self->{beta_cache}->{$doc->{id}}->{$current_label}->{$t};
}

sub compute_psi {
    my ($self,$doc,$current_label,$prev_label,$t) = @_;
    if(exists($self->{psi_cache}->{$doc->{id}}->{$current_label}->{$prev_label}->{$t})){
	return $self->{psi_cache}->{$doc->{id}}->{$current_label}->{$prev_label}->{$t};
    }
    return ($self->{psi_cache}->{$doc->{id}}->{$current_label}->{$prev_label}->{$t}
	    = exp(_dot($self->{weight},$self->compute_phi($doc,$current_label,$prev_label,$t))));
}

sub compute_phi {
    my ($self,$doc,$current_label,$prev_label,$t) = @_;
    my $vector = [];
    foreach my $func (@{ $self->{feature_functions} }){
	push @{ $vector }, $func->($doc,$current_label,$prev_label,$t);
    }
    return $vector;
}

sub compute_Z {
    my ($self,$doc) = @_;
    return $self->{alpha_cache}->{$doc->{id}}->{chr(0x1f)}->{scalar @{$doc->{labeled_sequence}} - 1};
}

sub compute_marginal_probability {
    my ($self,$doc,$current_label,$prev_label,$t) = @_;
    return 1.0 / $self->compute_Z($doc)
	* $self->compute_psi($doc,$current_label,$prev_label,$t)
	* $self->compute_alpha($doc,$prev_label,$t - 1)
	* $self->compute_beta($doc,$current_label,$t);
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

sub _multiply {
    my ($scalar, $vector) = @_;
    my $merged = [];
    for(my $i = 0; $i < @{ $vector }; $i++){
	push @{ $merged }, $scalar * $vector->[$i]
    }
    return $merged;

}

1;
