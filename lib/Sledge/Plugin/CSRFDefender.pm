package Sledge::Plugin::CSRFDefender;
use strict;
use warnings;
our $VERSION = '0.01';

our $SessionIdName = 'csrf_sid';
use constant FORBIDDEN => 403;
our $ForbiddenHTML = q{
<html>
  <head>
    <title>403 Forbidden</title>
  </head>
  <body>
    <h1>403 Forbidden</h1>
    <p>
      Session validation failed.
    </p>
  </body>
</html>
};

sub import {
    my $pkg = caller;

    # insert session id to form
    $pkg->add_trigger(
        BEFORE_DISPATCH => sub {
            my $self = shift;

            # copy from Sledge::SessionManager::StickyQuery
            $self->add_filter(
                sub {
                    my($self, $content) = @_;
                    my $sid = $self->session->session_id;
                    $content =~ s!(<form\s*.*?>)!$1\n<input type="hidden" name="$SessionIdName" value="$sid">!isg;
                    return $content;
                }
            );
        }
    );

    # access deny if don't send sid
    $pkg->add_trigger(
        BEFORE_DISPATCH => sub {
            my $self = shift;

            if (
                $self->is_post_request and
                not $self->finished    and
                ($self->r->param($SessionIdName) || '') ne $self->session->session_id
            ) {
                $self->r->content_type('text/html');
                $self->r->status(FORBIDDEN);
                $self->set_content_length(length $ForbiddenHTML);
                $self->send_http_header;
                $self->r->print($ForbiddenHTML);
                $self->finished(1);
            }
        }
    );
}

1;
__END__

=head1 NAME

Sledge::Plugin::CSRFDefender - CSRF defender

=head1 SYNOPSIS

    package Your::Pages;
    use Sledge::Plugin::CSRFDefender;

=head1 DESCRIPTION

Sledge::Plugin::CSRFDefender is CSRF defender plugin for sledge.

This plugin embeded a session id within form.

In POST Request, check the session_id and reject if invalid request.

=head1 AUTHOR

MATSUNO Tokuhiro E<lt>tokuhiro at mobilefactory.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Bundle::Sledge>

=cut
