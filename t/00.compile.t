use Test::More;

subtest sanity => sub {
	my @classes = qw(StupidStackLanguage::Stack StupidStackLanguage);
	foreach my $class ( @classes ) {
	 	BAIL_OUT( "$class did not compile: $@" ) unless require_ok( $class );
		}
	};

done_testing();
