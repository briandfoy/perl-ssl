package StupidStackLanguage;
use v5.34;
use experimental qw(signatures);

use IO::Interactive qw(interactive);

sub new ( $class, %args ) {
	state $rc = require StupidStackLanguage::Stack;
	state %defaults = (
		stack_class  => 'StupidStackLanguage::Stack',
		input        => \*STDIN,
		output       => \*STDOUT,
		error_output => \*STDERR,
		verbose      => 0,
		);

	my %opts = ( %defaults, %args );

	my $p = bless {
		cursor   => 0,
		err_fh   => $opts{error_output},
		fh       => $opts{output},
		input_fh => $opts{input},
		program  => [],
		stack    => $opts{stack_class}->new,
		verbose  => $opts{verbose},
		}, $class;
	}

sub _stack ( $p ) { $p->{stack} }

sub exit ( $p, $code = 0 ) {
	$p->verbose( "Exiting" );
	$p->verbose( $p->_stack->dump );
	exit $code;
	}

sub fh       ( $p ) { $p->{fh}       }
sub err_fh   ( $p ) { $p->{err_fh}   }
sub input_fh ( $p ) { $p->{input_fh} }

sub getchr ( $p ) {
	print { interactive } "char> ";
	chomp( my $answer = readline( $p->input_fh ) );
	my( $char ) = $answer =~ /\A(.)/;
	ord $char;
	}

sub getnum ( $p ) {
	print { interactive } "num> ";
	chomp( my $answer = readline( $p->input_fh ) );
	$answer + 0;
	}

sub get_operations ( $p ) {
	my %Operations = (
		'f' => sub ( $p ) { $p->output( chr $p->_stack->peek ) },

		'h' => sub ( $p ) { $p->_stack->push( $p->getnum ) },

		'j' => sub ( $p ) { $p->_stack->push( $p->getchr ) },
		'k' => sub ( $p ) {
			$p->{cursor}++ if $p->_stack->peek == 0;
			},

		't' => sub ( $p ) {
			return unless $p->_stack->peek == 0;
			while( ++$p->{cursor} ) {
				last if 'u' eq $p->{program}[$p->{cursor}];
				}
			},
		'u' => sub ( $p ) {
			return if $p->_stack->peek == 0;
			$p->verbose( "<u> sees " . $p->_stack->peek );
			while( --$p->{cursor} ) {
				last if 't' eq $p->{program}[$p->{cursor}];
				}
			$p->verbose( "next command is <" . $p->{program}[$p->{cursor}] . ">" );
			},

		'x' => sub ( $p ) { $p->output( $p->_stack->peek ) },
		'y' => sub ( $p ) { $p->{stack} = StupidStackLanguage::Stack->new },
		'z' => sub ( $p ) { $p->exit },
		);
	}

sub is_verbose ( $p ) { $p->{verbose} }

sub output( $p, @args ) { print { $p->fh } @args }

sub parse ( $self, $string ) {
	$string = lc($string);
	if( $string =~ /([^a-z])/ ) {
		my $pos = pos($string);
		warn "Illegal character <$1> at position <$pos>\n";
		return;
		}

	[ split //, $string ];
	}

sub run_command ( $p, $command ) {
	state %Operations = $p->get_operations;
	$p->verbose( "Running command <$command>" );

	my( $code, $arg ) = do {
		if( exists $Operations{$command} ) {
			( $Operations{$command}, $p )
			}
		elsif( my $c = $p->_stack->has_op( $command ) ) {
			( $c, $p->_stack )
			}
		else { sub { die "Unrecognized command <$command> at position <" . $p->{cursor} . ">\n" } }
		};

	$code->( $arg );
	$p->verbose( $p->_stack->dump( "After command <$command>" ) );
	}

sub run_program ( $class, $program, @opts ) {
	my $p = $class->new( @opts );

	$p->{program} = $p->parse( $program );

	while(1) {
		my $next_command = $p->{program}[ $p->{cursor} ];
		last unless $next_command;
		$p->run_command( $next_command );
		$p->{cursor}++;
		}
	}

sub verbose ( $p, $message ) {
	return unless $p->is_verbose;
	say { $p->err_fh } "!!! $message"
	}

1;
