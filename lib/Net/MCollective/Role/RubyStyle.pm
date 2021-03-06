package Net::MCollective::Role::RubyStyle;
use Moose::Role;

=head1 NAME

Net::MCollective::Role::RubyStyle - ruby-style hashes for YAML serialization

=head1 DESCRIPTION

This role provides a method to convert Moose objects (i.e. hashes with
bareword keys) into Ruby-style hashes with symbols for keys, suitable
for serializing to YAML for exchange with Ruby. 

The keys in the hash returned are just strings with ':' prepended, but
using YAML::Syck these are serialized in such a way that they are
deserialized to symbols by Ruby, once the quoting is removed - see
Serializer::YAML for the gory details.

Only "public" attributes are included in the hash - those with an
initial _ are excluded.

The conversion is recursive - if a value is encountered which responds
to this routine, it will be invoked and the returned hash used.

=head1 METHODS

=head2 ruby_style_hash

Returns the object's corresponding 'ruby-style hash'.

=cut

sub ruby_style_hash {
    my ($self) = @_;

    my $hash = {};

    for my $attr ($self->meta->get_all_attributes) {
        my $name = $attr->name;
        
        next if $name =~ /^_/;
        next unless exists $self->{$name};

        if (blessed $self->{$name} && $self->{$name}->can('ruby_style_hash')) {
            $hash->{':' . $name} = $self->{$name}->ruby_style_hash;
        }
        else {
            $hash->{':' . $name} = $self->{$name};
        }
    }

    if ($self->meta->has_attribute('_fields')) {
        for my $field (keys %{ $self->_fields }) {
            $hash->{':' . $field} = $self->_fields->{$field};
        }
    }

    return $hash;
}

1;
