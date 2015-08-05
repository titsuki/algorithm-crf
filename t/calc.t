use Test::More;

require_ok 'Algorithm::CRF';
require_ok 'Algorithm::CRF::Doc';

my @docs;
push @docs, Algorithm::CRF::Doc->new(observed_sequence => ['Apple','juice'],
				     labeled_sequence => ['drink','drink']);

push @docs, Algorithm::CRF::Doc->new(observed_sequence => ['Apple','drink'],
				     labeled_sequence => ['drink','drink']);

push @docs, Algorithm::CRF::Doc->new(observed_sequence => ['Apple','Inc'],
				     labeled_sequence => ['company','company']);
my $crf = Algorithm::CRF->new(docs => \@docs);
$crf->train();

done_testing;
