package StupidStackLanguage::Stack;
use v5.34;
use experimental qw(signatures);

use strict;

sub new ( $class ) { bless [], $class }
sub fh ( $s ) { \*STDOUT }
sub output( $s, @args ) { print { $s->fh } @args }

sub getchr ( $s ) { }

sub push  ( $s, @args ) { push $s->@*, @args }
sub pop   ( $s )        { pop $s->@* }
sub peek  ( $s )        { my $n = $s->pop; $s->push($n); $n }
sub clear ( $s )        { @$s = () }
sub size  ( $s )        { scalar @$s }

sub dump ( $s, $label = "Stack:" ) {
	my $dump = "\n$label";
	for( my $i = $s->size - 1; $i >= 0; $i-- ) {
		$dump .= "  $i: $s->[$i]\n";
		}
	$dump;
	}

# https://esolangs.org/wiki/StupidStackLanguage
sub get_operations ( $self ) {
	my %Operations = (
		'a' => sub ( $s ) { $s->push(0) },
		'b' => sub ( $s ) { $s->pop },
		'c' => sub ( $s ) {
			my( $first, $second ) = map { $s->pop } 0 .. 1;
			$s->push( $second, $first, $first + $second );
			},
		'd' => sub ( $s ) { $s->push( $s->pop - 1 ) },
		'e' => sub ( $s ) {
			my( $first, $second ) = map { $s->pop } 0 .. 1;
			$s->push( $second, $first, $first % $second );
			},

		'g' => sub ( $s ) { $s->push( $s->pop + $s->pop ) },

		'i' => sub ( $s ) { $s->push( $s->pop + 1 ) },

		'l' => sub ( $s ) { $s->push( $s->pop, $s->pop ) },
		'm' => sub ( $s ) {
			my( $first, $second ) = map { $s->pop } 0 .. 1;
			$s->push( $second, $first, $first * $second );
			},
		'n' => sub ( $s ) {
			my( $first, $second ) = map { $s->pop } 0 .. 1;
			$s->push( $second, $first, $first == $second ? 1 : 0 );
			},
		'o' => sub ( $s ) {
			my $n = $s->pop;
			my @sub = map { $s->pop } 2 .. $n;
			$s->push( $n, reverse(@sub) );
			},

		'p' => sub ( $s ) {
			my( $first, $second ) = map { $s->pop } 0 .. 1;
			$s->push( $second, $first, eval { $first / $second } );
			},
		'q' => sub ( $s ) { $s->push( ($s->pop) x 2 ) },
		'r' => sub ( $s ) { $s->push( $s->size ) },
		's' => sub ( $s ) {
			my $n = $s->pop;
			my @sub = map { $s->pop } 2 .. $n;
			my $last = pop @sub;
			$s->push( $n, reverse(@sub), $last );
			},

		'v' => sub ( $s ) { $s->push( $s->pop + 5 ) },
		'w' => sub ( $s ) { $s->push( $s->pop - 5 ) },
		);
	}

sub has_op ( $s, $op ) {
	state %Operations = $s->get_operations;
	return $Operations{$op} ? $Operations{$op} : ();
	}

1;
