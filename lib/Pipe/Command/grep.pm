package Pipe::Command::grep;
use Moose;
extends 'Pipe::Command';
use feature 'say';
use File::Next;
use Sub::Name;

has where => (
    isa           => 'Str',
    is            => 'rw',
    documentation => 'string to match',
    );
has where_sub => (
    traits        => ['NoGetopt'],
    isa           => 'CodeRef',
    is            => 'rw',
    );

sub go {
    my ($self, $session, $args) = @_;
    $self->where( $args->[0] ) unless $self->where;

    my $where = $self->where;
    my $sub = subname $where => eval "sub { $where }";

    $self->where_sub( $sub );
}

sub filter {
    my ($self, $session, @values) = @_;

    my $where_sub = $self->where_sub;

    return grep { 
        my $result = eval { $where_sub->($_) };
        die "ERR in grep: (for $_) $@" if $@;
        $result;
        } @values;
}

1;
