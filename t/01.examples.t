use v5.34;
use Test::More;
use experimental qw(signatures);

diag( Test::More->VERSION );

subtest sanity => sub {
	my @classes = qw(StupidStackLanguage::Stack StupidStackLanguage);
	foreach my $class ( @classes ) {
	 	BAIL_OUT( "$class did not compile: $@" ) unless require_ok( $class );
		}
	};

my @programs = (
	[ 'hello world', 'avdqvdmavvqmiqiiifvdlfbffiiiflblblfbqviiifbfiiifwdfwwiif', 'hello world' ],
	[ 'factorial', 'hqdtmldubx', 24, 4 ],
	[ 'box', 'jfffavvflflqvvvviifblflflfff', "ttt\nt t\nttt", 't' ],
	[ 'SSL', 'avvvvvvvvvvvvvvvviiifvvvvvviiififwfwddfwfwwwddfvvvvvviiifwwwwifiifviiifwwwwwwdfvvvvifvviiifwddfvvvdfwwwwfvifddf', 'StupidStackLanguage' ],
	);

foreach my $program ( @programs ) {
	subtest $program->[0] => sub {
		open my $sfh, '>:encoding(UTF-8)', \my $string;
		open my $efh, '>:encoding(UTF-8)', \my $error;

		pipe( my $reader, my $writer );
		$writer->autoflush(1);
		say { $writer } $program->[3] if defined $program->[3];
		my $f = StupidStackLanguage->run_program( $program->[1],
			output       => $sfh,
			error => \*STDERR,
			input        => $reader,
			);
		close $writer;
		close $reader;
		close $sfh;
		close $efh;
		is( $string, $program->[2], "Output is correct" );
		};
	}

done_testing();
