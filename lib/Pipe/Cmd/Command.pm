package Pipe::Cmd::Command::ls;
use Moose;
use Data::Dumper;
extends 'MooseX::App::Cmd::Command';
use feature 'say';

has show_all => (
    # metaclass => 'MooseX::Getopt::Meta::Attribute',
    traits => [ 'Getopt' ],
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'A',
    documentation => 'show all files, including hidden ones',
    );

has bean => (
    isa => 'Str',
    is  => 'rw',
    traits => [ 'NoGetopt' ],
    );

sub execute {
    my ($self, $opt, $args) = @_;

    local $Data::Dumper::Maxdepth = 3;
    local $Data::Dumper::Indent   = 1;

    say Dumper($self);
}

1;
