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
		stop         => 0,
		);

	my $hooks = delete $args{hooks} // {};

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

	$p->_set_hooks( $hooks );

	$SIG{INT} = sub {
		warn( "Caught SIGINT. Stopping.\n" );
		$p->stop;
		};

	return $p;
	}

sub _set_hooks ( $p, $hash ) {
	state %default_hooks = (
		pre_parse    => sub ( $program ) { $program },
		post_parse   => sub ( $program ) { return },

		pre_run      => sub ( $p ) { return },
		post_run     => sub ( $p ) { return },

		pre_command  => sub ( $invocant, $command ) { return },
		post_command => sub ( $invocant, $command ) { return },
		);

	my %hooks = ( %default_hooks, $hash->%* );
	# XXX check hooks

	$p->{hooks} = \%hooks;
	}

sub _stack ( $p ) { $p->{stack} }

sub exit ( $p, $code = 0 ) {
	$p->verbose( "Exiting" );
	$p->verbose( $p->_stack->dump );
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
			my %seen;
			$seen{t} = 1;
			$seen{u} = 0;
			while( ++$p->{cursor} ) {
				$seen{t}++ if $p->current_command_is('t');
				$seen{u}++ if $p->current_command_is('u');
				last if $p->current_command_is('u') && $seen{t} == $seen{u};
				}
			},
		'u' => sub ( $p ) {
			return if $p->_stack->peek == 0;
			my %seen;
			$seen{t} = 0;
			$seen{u} = 1;
			while( --$p->{cursor} ) {
				$seen{t}++ if $p->current_command_is('t');
				$seen{u}++ if $p->current_command_is('u');
				last if $p->current_command_is('t') && $seen{t} == $seen{u};
				}
			$p->verbose( "next command is <" . $p->current_command . ">" );
			},

		'x' => sub ( $p ) { $p->output( $p->_stack->peek ) },
		'y' => sub ( $p ) { $p->{stack} = StupidStackLanguage::Stack->new },
		'z' => sub ( $p ) { $p->{cursor} = $p->_stack->size; $p->stop; }, # one past program
		);
	}

sub is_verbose ( $p ) { $p->{verbose} }

sub current_command ( $p ) { $p->{program}[ $p->{cursor} ] }
sub current_command_is ( $p, $command ) { $command eq $p->current_command }

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

	$p->pre_command( $arg, $code );
	$code->( $arg );
	$p->post_command( $arg, $code );

	$p->verbose( "After command <$command>:" . $p->_stack->dump );
	}

sub run_program ( $class, $program, @opts ) {
	my $p = $class->new( @opts );

	$program = $p->pre_parse( $program );
	$p->{program} = $p->parse( $program );
	$p->post_parse;

	$p->pre_run;
	while(1) {
		last if $p->{stop};
		my $current_command = $p->current_command;
		last unless $current_command;
		$p->verbose( $p->show_program );
		$p->run_command( $current_command );
		$p->{cursor}++;
		}
	$p->post_run;
	}

sub show_program ( $p ) {
	my $pos = $p->{cursor};
	my $program = join( '', $p->{program}->@* ) . "\n"
		. ( ' ' x ($pos - 1) ) . "*\n";
	}

sub stop ( $p ) { $p->{stop} = 1 }

sub verbose ( $p, $message ) {
	return unless $p->is_verbose;
	$message =~ s/^/!!! /gm;
	say { $p->err_fh } $message
	}

=head2 Hooks

=over 4

=item * hooks

Returns a hash reference of all the hooks.

=cut

sub hooks ( $p ) { my %h = $p->{hooks}->%*; \%h }

=item * pre_command( RUNNER, INVOCANT, CODE_REF )

Run the pre-command hook once the command is selected. The arguments
are the invocant for the command (either the program runner or the
stack) and the code reference it will run.

=cut

sub pre_command ( $p, $invocant, $code_ref ) {
	return unless $p->hooks->{pre_command};
	$p->hooks->{pre_command}->( $invocant, $code_ref );
	}

=item * pre_parse

Runs the pre-parse hook, passing passing the input program as is. The
result of C<pre_parse> replaces the input program.

The default simply returns its argument.

=cut

sub pre_parse ( $p, $program ) {
	return unless $p->hooks->{pre_parse};
	$p->hooks->{pre_parse}->( $program );
	}

=item * pre_run

Runs the pre-run hook a

=cut

sub pre_run ( $p ) {
	return unless $p->hooks->{pre_run};
	$p->hooks->{pre_run}->( $p );
	}

=item * post_command( RUNNER, INVOCANT, COMMAND )

Runs after a command has done its work. It takes as arguments the object
that handles the command and the command.

=cut

sub post_command ( $p, $invocant, $command ) {
	return unless $p->hooks->{post_command};
	$p->hooks->{post_command}->( $invocant, $command );
	}

=item * post_parse( RUNNER, PROGRAM )

Runs the pre-run hook passing the parsed program as its argument,
right before the parsed program starts to run.

The default does nothing.

=cut

sub post_parse ( $p ) {
	return unless $p->hooks->{post_parse};
	$p->hooks->{post_parse}->( $p->{program} );
	}

=item * post_run( RUNNER )

Runs after the program stops.

=cut

sub post_run ( $p ) {
	return unless $p->hooks->{post_run};
	$p->hooks->{post_run}->( $p );
	}

=back

=cut

1;
