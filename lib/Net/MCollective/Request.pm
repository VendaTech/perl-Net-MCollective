package Net::MCollective::Request;
use Moose;
use Digest::MD5 qw(md5 md5_hex md5_base64);

has 'callerid' => (isa => 'Str', is => 'ro', required => 1);
has 'senderid' => (isa => 'Str', is => 'ro', required => 1);

has 'msgtime' => (isa => 'Int', is => 'rw', required => 0);
has 'requestid' => (isa => 'Str', is => 'rw', required => 0);

has 'hash' => (isa => 'Str', is => 'rw', required => 0);
has 'body' => (isa => 'Str', is => 'rw', required => 0);

has 'filter' => (isa => 'HashRef[ArrayRef]', is => 'ro', required => 0,
                 default => sub {
                     { identity => [], fact => [], agent => [], cf_class => [] } 
                 });

has 'msgtarget' => (isa => 'Str', is => 'rw', required => 0);

sub BUILD {
    my ($self) = @_;
    $self->msgtime(time());
    $self->requestid(md5_hex(time() . $$));
}

sub ruby_style_hash {
    my ($self) = @_;

    my $hash = {};

    for my $attr ($self->meta->get_all_attributes) {
        my $name = $attr->name;
        
        next if $name =~ /^_/;
        next unless exists $self->{$name};

        $hash->{':' . $name} = $self->{$name};
    }
    
    return $hash;
}

__PACKAGE__->meta->make_immutable;
