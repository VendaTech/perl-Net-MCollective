package Net::MCollective::Serializer::YAML;
use Moose;

=head1 NAME

Net::MCollective::Serializer::YAML - MCollective-compatible YAML routines

=cut

use YAML::Syck;

extends 'Net::MCollective::Serializer';

no Moose;

=head1 METHODS

=head2 serialize

Dump the given data structure to YAML, in an MCollective-compatible
fashion. We use YAML::Syck for bug-compatibility, but must unquote the
ruby-style hash keys.

=cut

sub serialize {
    my ($self, $data) = @_;

    my $yaml = Dump($data);

    # un-double-quote keys
    $yaml =~ s/^(\s*)":(.+?)":/$1:$2:/gm;

    # un-single-quote integers
    $yaml =~ s/'(\d+)'/$1/gm;

    return $yaml;
}

=head2 deserialize

Load a YAML document, returning the corresponding data structure. 

=cut

sub deserialize {
    my ($self, $yaml) = @_;
    my $data = Load($yaml);
    return $data;
}

__PACKAGE__->meta->make_immutable;
