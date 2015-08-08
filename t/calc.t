use Test::More;
use Data::Dumper;

require_ok 'Algorithm::CRF';
require_ok 'Algorithm::CRF::Doc';
require_ok 'Algorithm::Viterbi';

my $crf = Algorithm::CRF->new(labels => ['drink','cake']);

# c1 = drink
# c2 = cake

my $doc = Algorithm::CRF::Doc->new(observed_sequence => ['A','B','C','D'],
				   labeled_sequence => [chr(0x1e),'drink','drink','cake','cake',chr(0x1f)],
				   id => 0);

$crf->{psi_cache}->{$doc->{id}}->{'drink'}->{chr(0x1e)}->{1} = 1.0;
$crf->{psi_cache}->{$doc->{id}}->{'cake'}->{chr(0x1e)}->{1} = 1.0;

$crf->{psi_cache}->{$doc->{id}}->{'drink'}->{'drink'}->{2} = 0.2;
$crf->{psi_cache}->{$doc->{id}}->{'drink'}->{'cake'}->{2} = 0.3;
$crf->{psi_cache}->{$doc->{id}}->{'cake'}->{'drink'}->{2} = 0.1;
$crf->{psi_cache}->{$doc->{id}}->{'cake'}->{'cake'}->{2} = 0.1;

$crf->{psi_cache}->{$doc->{id}}->{'drink'}->{'drink'}->{3} = 0.2;
$crf->{psi_cache}->{$doc->{id}}->{'drink'}->{'cake'}->{3} = 0.2;
$crf->{psi_cache}->{$doc->{id}}->{'cake'}->{'drink'}->{3} = 0.1;
$crf->{psi_cache}->{$doc->{id}}->{'cake'}->{'cake'}->{3} = 0.1;

$crf->{psi_cache}->{$doc->{id}}->{'drink'}->{'drink'}->{4} = 0.3;
$crf->{psi_cache}->{$doc->{id}}->{'drink'}->{'cake'}->{4} = 0.1;
$crf->{psi_cache}->{$doc->{id}}->{'cake'}->{'drink'}->{4} = 0.2;
$crf->{psi_cache}->{$doc->{id}}->{'cake'}->{'cake'}->{4} = 0.1;

$crf->{psi_cache}->{$doc->{id}}->{chr(0x1f)}->{'drink'}->{5} = 1.0;
$crf->{psi_cache}->{$doc->{id}}->{chr(0x1f)}->{'cake'}->{5} = 1.0;

$crf->_compute_cache($doc);
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

is($crf->compute_Z($doc),0.084);

is(sprintf("%.3lf",$crf->compute_marginal_probability($doc,'drink','drink',3)),0.595);
is(sprintf("%.3lf",$crf->compute_marginal_probability($doc,'drink','cake',3)),0.238);
is(sprintf("%.3lf",$crf->compute_marginal_probability($doc,'cake','drink',3)),0.119);
is(sprintf("%.3lf",$crf->compute_marginal_probability($doc,'cake','cake',3)),0.048);

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
    return 1 if($current_label eq chr(0x1f) && $prev_label eq 'cake');
    return 0;
};

push @feature_functions, sub {
    my ($doc,$current_label,$prev_label,$t) = @_;
    my $observed_sequence = join(chr(0x1d),@{ $doc->{observed_sequence} });
    return 0 if($observed_sequence ne join(chr(0x1d),qw/A B C D/));
    return 1 if($current_label eq 'cake' && $prev_label eq chr(0x1e));
    return 0;
};

my $doc1 = Algorithm::CRF::Doc->new(observed_sequence => ['A','B','C','D'],
				    labeled_sequence => [chr(0x1e),'drink','drink','cake','cake',chr(0x1f)]);
my $doc2 = Algorithm::CRF::Doc->new(observed_sequence => ['X','B','X','D'],
				    labeled_sequence => [chr(0x1e),'drink','drink','cake','cake',chr(0x1f)]);

my @docs;
push @docs,$doc1;
push @docs,$doc2;

my $crf = Algorithm::CRF->new(docs => \@docs,feature_functions => \@feature_functions,labels => ['drink','cake'],iter_limit => 1000);
$crf->train();
print STDERR Dumper($crf->{weight});

my $doc = Algorithm::CRF::Doc->new(observed_sequence => ['A','B','X','D']);
my $viterbi = Algorithm::Viterbi->new(doc => $doc, CRF => $crf, labels => ['drink','cake']);
$viterbi->construct_lattice();

done_testing;
