# Copyright (C) 2008-2009, Sebastian Riedel.

package Mojo::Cookie;

use strict;
use warnings;

use base 'Mojo::Base';
use overload '""' => sub { shift->to_string }, fallback => 1;

use Carp 'croak';
use Mojo::ByteStream 'b';
use Mojo::Date;

__PACKAGE__->attr(
    [qw/comment domain httponly max_age name path port secure value version/]
);

# Regex
my $COOKIE_SEPARATOR_RE = qr/^\s*\,\s*/;
my $EXPIRES_RE          = qr/^([^\;]+)\s*/;
my $NAME_RE             = qr/
    ^\s*           # Start
    ([^\=\;\,]+)   # Relaxed Netscape token, allowing whitespace
    \s*\=?\s*      # '=' (optional)
/x;
my $SEPARATOR_RE = qr/^\s*\;\s*/;
my $STRING_RE    = qr/^([^\;\,]+)\s*/;
my $VALUE_RE     = qr/
    ^\s*               # Start
    (\"                # Quote
    (!:\\(!:\\\")?)*   # Value
    \")                # Quote
/x;

# My Homer is not a communist.
# He may be a liar, a pig, an idiot, a communist, but he is not a porn star.
sub expires {
    my ($self, $expires) = @_;
    if (defined $expires) {
        $self->{expires} = Mojo::Date->new($expires) unless ref $expires;
    }
    return $self->{expires};
}

sub to_string { croak 'Method "to_string" not implemented by subclass' }

sub _tokenize {
    my ($self, $string) = @_;

    my (@tree, @token);
    while ($string) {

        # Name
        if ($string =~ s/$NAME_RE//) {

            my $name = $1;
            my $value;

            # Quoted value
            if ($string =~ s/$VALUE_RE//) { $value = b($1)->unquote }

            # "expires" is a special case, thank you Netscape...
            elsif ($name =~ /expires/i && $string =~ s/$EXPIRES_RE//) {
                $value = $1;
            }

            # Unquoted string
            elsif ($string =~ s/$STRING_RE//) { $value = $1 }

            push @token, [$name, $value];

            # Separator
            $string =~ s/$SEPARATOR_RE//;

            # Cookie separator
            if ($string =~ s/$COOKIE_SEPARATOR_RE//) {
                push @tree, [@token];
                @token = ();
            }
        }

        # Bad format
        else {last}

    }

    # No separator
    push @tree, [@token] if @token;

    return @tree;
}

1;
__END__

=head1 NAME

Mojo::Cookie - Cookie Base Class

=head1 SYNOPSIS

    use base 'Mojo::Cookie';

=head1 DESCRIPTION

L<Mojo::Cookie> is a cookie base class.

=head1 ATTRIBUTES

L<Mojo::Cookie> implements the following attributes.

=head2 C<comment>

    my $comment = $cookie->comment;
    $cookie     = $cookie->comment('test 123');

=head2 C<domain>

    my $domain = $cookie->domain;
    $cookie    = $cookie->domain('localhost');

=head2 C<expires>

    my $expires = $cookie->expires;
    $cookie     = $cookie->expires(time + 60);

=head2 C<httponly>

    my $httponly = $cookie->httponly;
    $cookie      = $cookie->httponly(1);

=head2 C<max_age>

    my $max_age = $cookie->max_age;
    $cookie     = $cookie->max_age(60);

=head2 C<name>

    my $name = $cookie->name;
    $cookie  = $cookie->name('foo');

=head2 C<path>

    my $path = $cookie->path;
    $cookie  = $cookie->path('/test');

=head2 C<port>

    my $port = $cookie->port;
    $cookie  = $cookie->port('80 8080');

=head2 C<secure>

    my $secure = $cookie->secure;
    $cookie    = $cookie->secure(1);

=head2 C<value>

    my $value = $cookie->value;
    $cookie   = $cookie->value('/test');

=head2 C<version>

    my $version = $cookie->version;
    $cookie     = $cookie->version(1);

=head1 METHODS

L<Mojo::Cookie> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<to_string>

    my $string = $cookie->to_string;

=cut
