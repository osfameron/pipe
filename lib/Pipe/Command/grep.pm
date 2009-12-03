package Pipe::Command::grep;
use Moose;
extends 'Pipe::Command';

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
    lazy_build    => 1,
    );

sub _build_where_sub {
    my $self = shift;

    my $where = $self->where;
    return subname $where => eval "sub { $where }";
}

sub go {
    my ($self, $session, $args) = @_;
    $self->where( $args->[0] ) unless $self->where;
}

sub filter {
    my ($self, $session, $iterator) = @_;

    my $where_sub = $self->where_sub;

    my @queue;
    return sub {
        return pop @queue if @queue;
        {
        my @values = $iterator->()
            or return;
        @queue = grep {
            my $result = eval { $where_sub->($_) };
            die "ERR in grep: (for $_) $@" if $@;
            $result;
            } @values;
        redo unless @queue;
        }
        return pop @queue;
    };
}

1;
