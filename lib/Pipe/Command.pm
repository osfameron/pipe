package Pipe::Command;
use Moose;
extends 'MooseX::App::Cmd::Command';
with    'MooseX::Getopt::Dashes';
use DateTime;
# use MooseX::Types::DateTime qw/DateTime/;
use YAML::XS;
use Pipe;

use Pipe::Session;

# Base class
# defaults to YAML etc.

has datestamp => (
    is      => 'rw',
    isa     => 'DateTime',
    default => sub { DateTime->now() },
    traits => ['NoGetopt'],
);

has pretty => (
    is      => 'rw',
    isa     => 'Bool',
);

sub execute {
    my ($self, undef, $args) = @_;

    my $session = Pipe::Session->new();
    $session->push_command( $self );

    $self->go( $session, $args );

    $self->connect_input( $session ) unless $session->iterator;

    my $it = $session->iterator
        or return $self->no_iterator($session, $args);


    my $filtered_it = $self->filter($session, $it);

    $session->iterator($filtered_it);
    $self->connect_output( $session );
}

sub connect_input {
    my ($self, $session) = @_;

    return unless -p *STDIN;

    my $string = <STDIN>;
    my $it = $self->mk_reader(*STDIN);

    my $header = $it->();
    my $command_stack = $header->{command_stack} || [];
    $session->push_command( @$command_stack );

    $session->iterator($it);
}

# YUCK, extract this elsewhere
sub mk_reader {
    my ($self, $fh) = @_;

    my (@buffer, $next);

    return sub {
        @buffer = $next ? ($next) : (); undef $next;
        while (defined (my $line = <$fh>)) {
            if ($line =~ /^---/ and @buffer) {
                $next = $line;
                last;
            }
            push @buffer, $line;
        }

        my $yaml = join '', @buffer;

        return Load($yaml);
    };
}

sub output_header {
    my ($self, $session) = @_;

    # better, $session->header, TODO
    print Dump( { command_stack => [ $session->all_commands ] } );
}

sub connect_output {
    my ($self, $session) = @_;

    my $pretty = $self->pretty || ! -p *STDOUT;

    if ($pretty) {
        my $formatter_command = $session->first_command(
            # TODO this should be role
            sub { $_->can('pretty_print') } 
            )
            or die "No pretty printer for this request!";
        $formatter_command->pretty_print($session);
    } else {
        $self->connect_output_yaml($session);
    }
}
sub connect_output_yaml {
    my ($self, $session) = @_;

    $self->output_header($session);
    my $it = $session->iterator;

    while (my @values = $it->()) {
        print Dump($_) for @values;
    }
}

sub go {
    die "Nothing to do?  Please override 'go' in your subclass!";
}

sub no_iterator {
    die "No iterator";
}

sub filter {
    my ($self, $session, $it) = @_;
    return $it;
}

1;
