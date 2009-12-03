package Pipe::Command::grep;
use Moose;
extends 'Pipe::Command';
use feature 'say';
use File::Next;

has where => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'string to match',
    );

sub go {
    my ($self, $session, $args) = @_;
    $self->where( $args->[0] ) unless $self->where;
}

sub filter {
    my ($self, $session, @values) = @_;

    my $where = $self->where;
    return grep { eval $where } @values;
}

sub ___pretty_print {
    my ($self, $session) = @_;

    print "I AM TEH GREP!";
}

1;
