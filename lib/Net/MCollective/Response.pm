package Net::MCollective::Response;
use Moose;

has 'senderid' => (isa => 'Str', is => 'ro', required => 1);
has 'body' => (isa => 'Str', is => 'ro', required => 1);
has 'hash' => (isa => 'Str', is => 'ro', required => 1);
has 'status' => (isa => 'Bool', is => 'rw', required => 0);

sub new_from_frame {
    my ($class, $frame) = @_;

    use YAML::XS;
    my $reply = Load($frame->body);
    
    $class->new(
        senderid => $reply->{":senderid"},
        body => $reply->{":body"},
        hash => $reply->{":hash"},
    );
}

__PACKAGE__->meta->make_immutable;
