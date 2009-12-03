package Pipe::Command::find;
use Moose;
extends 'Pipe::Command';
use MooseX::Types::Path::Class qw(File to_File);
use feature 'say';
use File::Next;

has show_all => (
    traits => [ 'Getopt' ],
    isa           => 'Bool',
    is            => 'rw',
    cmd_aliases   => 'A',
    documentation => 'show all files, including hidden ones (TODO)',
    );

sub go {
    my ($self, $session, $args) = @_;

    my @files = @$args;
    push @files, '.' unless @files;

    my $it = File::Next::files( @files );

    $session->iterator(
        sub {
            if (my $file = $it->()) {
                return to_File($file);
            } else {
                return;
            }
        });
}

sub pretty_print {
    my ($self, $session) = @_;

    print "List of files found!\n\n";
    my $it = $session->iterator;
    while (my @files = $it->()) {
        print join "\n", @files;
        print "\n";
    }
    print "\n";
}

1;
