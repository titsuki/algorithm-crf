use Test::More;

require_ok 'Algorithm::CRF';
require_ok 'Algorithm::CRF::Doc';

my $doc = Algorithm::CRF::Doc->new(observed_sequence => ['A','B','C','D'],
				   labeled_sequence => [chr(0x1e),'drink','drink','cake','cake',chr(0x1f)]);
my @docs;
push @docs,$doc;

my $crf = Algorithm::CRF->new(docs => \@docs,feature_functions => \@feature_functions,labels => ['drink','cake']);

# c1 = drink
# c2 = cake

$crf->{psi_cache}->{'drink'}->{chr(0x1e)}->{1} = 1.0;
$crf->{psi_cache}->{'cake'}->{chr(0x1e)}->{1} = 1.0;

$crf->{psi_cache}->{'drink'}->{'drink'}->{2} = 0.2;
$crf->{psi_cache}->{'drink'}->{'cake'}->{2} = 0.3;
$crf->{psi_cache}->{'cake'}->{'drink'}->{2} = 0.1;
$crf->{psi_cache}->{'cake'}->{'cake'}->{2} = 0.1;

$crf->{psi_cache}->{'drink'}->{'drink'}->{3} = 0.2;
$crf->{psi_cache}->{'drink'}->{'cake'}->{3} = 0.2;
$crf->{psi_cache}->{'cake'}->{'drink'}->{3} = 0.1;
$crf->{psi_cache}->{'cake'}->{'cake'}->{3} = 0.1;

$crf->{psi_cache}->{'drink'}->{'drink'}->{4} = 0.3;
$crf->{psi_cache}->{'drink'}->{'cake'}->{4} = 0.1;
$crf->{psi_cache}->{'cake'}->{'drink'}->{4} = 0.2;
$crf->{psi_cache}->{'cake'}->{'cake'}->{4} = 0.1;

$crf->{psi_cache}->{chr(0x1f)}->{'drink'}->{5} = 1.0;
$crf->{psi_cache}->{chr(0x1f)}->{'cake'}->{5} = 1.0;

is($crf->compute_alpha($doc,chr(0x1e),0),1.0);

is($crf->compute_alpha($doc,'drink',1),1);
is($crf->compute_alpha($doc,'cake',1),1);

is($crf->compute_alpha($doc,'drink',2),0.5);
is($crf->compute_alpha($doc,'cake',2),0.2);

is($crf->compute_alpha($doc,'drink',3),0.14);
is($crf->compute_alpha($doc,'cake',3),0.07);

is($crf->compute_alpha($doc,'drink',4),0.049);
is($crf->compute_alpha($doc,'cake',4),0.035);

is($crf->compute_alpha($doc,chr(0x1f),5),0.084);

is($crf->compute_beta($doc,chr(0x1f),5),1);

is($crf->compute_beta($doc,'drink',4),1);
is($crf->compute_beta($doc,'cake',4),1);

is($crf->compute_beta($doc,'drink',3),0.5);
is($crf->compute_beta($doc,'cake',3),0.2);

is($crf->compute_beta($doc,'drink',2),0.12);
is($crf->compute_beta($doc,'cake',2),0.12);

is($crf->compute_beta($doc,'drink',1),0.036);
is($crf->compute_beta($doc,'cake',1),0.048);

is($crf->compute_beta($doc,chr(0x1e),0),0.084);

my @feature_functions;
push @feature_functions, sub {
    my ($doc,$current_label,$prev_label,$t) = @_;
    my $observed_sequence = join(chr(0x1d),@{ $doc->{observed_sequence} });
    return 0 if($observed_sequence ne join(chr(0x1d),qw/A B C D/));
    return 1 if($current_label eq 'drink' && $prev_label eq 'drink');
    return 0;
};

push @feature_functions, sub {
    my ($doc,$current_label,$prev_label,$t) = @_;
    my $observed_sequence = join(chr(0x1d),@{ $doc->{observed_sequence} });
    return 0 if($observed_sequence ne join(chr(0x1d),qw/A B C D/));
    return 1 if($current_label eq 'drink' && $prev_label eq 'cake');
    return 0;
};

push @feature_functions, sub {
    my ($doc,$current_label,$prev_label,$t) = @_;
    my $observed_sequence = join(chr(0x1d),@{ $doc->{observed_sequence} });
    return 0 if($observed_sequence ne join(chr(0x1d),qw/A B C D/));
    return 1 if($current_label eq 'cake' && $prev_label eq 'cake');
    return 0;
};

push @feature_functions, sub {
    my ($doc,$current_label,$prev_label,$t) = @_;
    my $observed_sequence = join(chr(0x1d),@{ $doc->{observed_sequence} });
    return 0 if($observed_sequence ne join(chr(0x1d),qw/A B C D/));
    return 1 if($current_label eq 'cake' && $prev_label eq 'drink');
    return 0;
};

push @feature_functions, sub {
    my ($doc,$current_label,$prev_label,$t) = @_;
    my $observed_sequence = join(chr(0x1d),@{ $doc->{observed_sequence} });
    return 0 if($observed_sequence ne join(chr(0x1d),qw/A B C D/));
    return 1 if($current_label eq chr(0x1d) && $prev_label eq 'cake');
    return 0;
};

push @feature_functions, sub {
    my ($doc,$current_label,$prev_label,$t) = @_;
    my $observed_sequence = join(chr(0x1d),@{ $doc->{observed_sequence} });
    return 0 if($observed_sequence ne join(chr(0x1d),qw/A B C D/));
    return 1 if($current_label eq 'cake' && $prev_label eq chr(0x1d));
    return 0;
};

done_testing;
