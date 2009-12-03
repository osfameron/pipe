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

    my $filtered_it = sub {
        if (my @values = $it->()) {
            return $self->filter($session, @values);
        }
    };

    $self->connect_output( $session, $filtered_it );
}

sub connect_input {
    my ($self, $session) = @_;

    return unless -p *STDIN;

    my $string = <STDIN>;
    my $it = $self->mk_reader(*STDIN);

    my $header = $it->();
    use Data::Dumper;
    die Dumper($header);
    my $command_stack = $header->command_stack || [];
    $session->push_command( @$command_stack );

    $session->iterator($it);
}

# YUCK, extract this elsewhere
sub mk_reader {
    my ($self, $fh) = @_;

    my $sep = local $/ = "\n---";

    my $buffer;

    return sub {
        my $header = $buffer || <$fh>;
        return unless defined $header;
        defined (my $chunk = <$fh>) or die "YAML header, but no body?";

        $buffer = $chunk=~s/^(---.*)?$//;

        my $yaml = join '', $header, $chunk;

        return Load($yaml);
    };
}

sub output_header {
    my ($self, $session) = @_;

    # better, $session->header, TODO
    print Dump( { command_stack => $session->all_commands } );
}

sub connect_output {
    my ($self, $session, $it) = @_;

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
    my ($self, $session, @values) = @_;
    return @values;
}

1;
