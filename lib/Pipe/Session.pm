package Pipe::Session;
use Moose;

use MooseX::Types::Moose qw/ CodeRef ArrayRef /;

has iterator => (
    is  => 'rw',
    isa => CodeRef,
);

has command_stack => (
    is      => 'rw',
    traits  => ['Array'],
    isa     => ArrayRef['Pipe::Command'],
    default => sub { [] },
    handles => {
        all_commands  => 'elements',
        push_command  => 'push',
        get_command   => 'get',
        first_command => 'first',
    },
);

1;
