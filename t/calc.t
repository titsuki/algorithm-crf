use Test::More;

require_ok 'Algorithm::CRF';
require_ok 'Algorithm::CRF::Doc';

my @docs;
my $RS = '0x30';
push @docs, Algorithm::CRF::Doc->new(observed_sequence => ['A','B','C','D'],
				     labeled_sequence => ['0x1e','drink','drink','cake','cake','0x1e']);

my @feature_functions;
push @feature_functions, sub {
    my ($observed_sequence,$current_label,$prev_label,$t) = @_;
    $observed_sequence = join('0x30',@{ $observed_sequence });
    return 0 if($observed_sequence ne join('0x30',qw/A B C D/));
    return 1 if($current_label eq 'drink' && $prev_label eq 'drink');
    return 0;
};

push @feature_functions, sub {
    my ($observed_sequence,$current_label,$prev_label,$t) = @_;
    $observed_sequence = join('0x30',@{ $observed_sequence });
    return 0 if($observed_sequence ne join('0x30',qw/A B C D/));
    return 1 if($current_label eq 'drink' && $prev_label eq 'cake');
    return 0;
};

push @feature_functions, sub {
    my ($observed_sequence,$current_label,$prev_label,$t) = @_;
    $observed_sequence = join('0x30',@{ $observed_sequence });
    return 0 if($observed_sequence ne join('0x30',qw/A B C D/));
    return 1 if($current_label eq 'cake' && $prev_label eq 'cake');
    return 0;
};

push @feature_functions, sub {
    my ($observed_sequence,$current_label,$prev_label,$t) = @_;
    $observed_sequence = join('0x30',@{ $observed_sequence });
    return 0 if($observed_sequence ne join('0x30',qw/A B C D/));
    return 1 if($current_label eq 'cake' && $prev_label eq 'drink');
    return 0;
};

push @feature_functions, sub {
    my ($observed_sequence,$current_label,$prev_label,$t) = @_;
    $observed_sequence = join('0x30',@{ $observed_sequence });
    return 0 if($observed_sequence ne join('0x30',qw/A B C D/));
    return 1 if($current_label eq '0x30' && $prev_label eq 'cake');
    return 0;
};

push @feature_functions, sub {
    my ($observed_sequence,$current_label,$prev_label,$t) = @_;
    $observed_sequence = join('0x30',@{ $observed_sequence });
    return 0 if($observed_sequence ne join('0x30',qw/A B C D/));
    return 1 if($current_label eq 'cake' && $prev_label eq '0x30');
    return 0;
};

my $crf = Algorithm::CRF->new(docs => \@docs,feature_functions => \@feature_functions);


$crf->train();

done_testing;
