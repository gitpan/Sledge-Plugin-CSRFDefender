use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use Sledge::TestPages";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 3);
}

# -------------------------------------------------------------------------

package Mock::Pages;
use base qw(Sledge::TestPages);
use Sledge::Plugin::CSRFDefender;
use Test::More;

__PACKAGE__->add_trigger(
    AFTER_INIT => sub {
        my $self = shift;
        for my $q (split /&/, $ENV{QUERY_STRING}) {
            my ($a, $b) = split /=/, $q;
            $self->r->param($a => $b);
        }
    },
);

sub dispatch_foo { }

sub dispatch_post { }

# -------------------------------------------------------------------------

package main;

my $d = $Mock::Pages::TMPL_PATH;
$Mock::Pages::TMPL_PATH = 't/tmpl/';
my $c = $Mock::Pages::COOKIE_NAME;
$Mock::Pages::COOKIE_NAME = 'sid';
$ENV{HTTP_COOKIE}    = "sid=SIDSIDSIDSID";

# insert session id
{
    my $page = Mock::Pages->new;
    $page->dispatch('foo');

    my $out = $page->output;
    like $out, qr(<input type="hidden" name="csrf_sid" value="SIDSIDSIDSID">), 'insert session id';
}

# -------------------------------------------------------------------------

# reject

{
    $ENV{REQUEST_METHOD} = 'POST';

    my $page = Mock::Pages->new;
    $page->dispatch('post');
    my $out = $page->output;
    like $out, qr(Status: 403), 'post failed';
}

# -------------------------------------------------------------------------

# accept

{
    $ENV{REQUEST_METHOD} = 'POST';
    $ENV{QUERY_STRING}   = 'name=miyagawa&csrf_sid=SIDSIDSIDSID';

    my $page = Mock::Pages->new;
    $page->dispatch('post');
    my $out = $page->output;
    like $out, qr(succeed), 'post succeeded';
}
