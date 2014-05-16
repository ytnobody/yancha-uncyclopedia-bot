#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Log::Minimal;
use AnyEvent;

use File::Spec;
use File::Basename 'dirname';
use lib (
    File::Spec->catdir(dirname(__FILE__), 'lib'),
    File::Spec->catdir(dirname(__FILE__), 'local', 'lib'),
    glob(File::Spec->catdir(dirname(__FILE__), 'submodules', '*', 'lib')),
);
use Unruly;
use WWW::Uncyclopedia;

$WWW::Uncyclopedia::BASE_URL = 'http://ansaikuropedia.org/';

my $bot_name = '物思い君';
my @tags = qw/PUBLIC/;

my $bot = Unruly->new(
    url  => 'http://yancha.hachiojipm.org',
    tags => {map {($_ => 1)} @tags},
    ping_intervals => 15,
);

unless( $bot->login($bot_name) ) {
    critf('Login failure');
    exit;
}

my $cv = AnyEvent->condvar;

$bot->run(sub {
    my ($client, $socket) = @_;

    infof('runnings at pid %s', $$);

    $socket->on('user message' => sub {
        my ($_socket, $message) = @_;

        if ($message->{is_message_log}) {
            ### ++などに反応させたい場合はここにロジックを書く
        }
        else {
            unless ($message->{nickname} eq $bot_name) {
                infof('received "%s" (from:%s)', $message->{text}, $message->{nickname});
                my ($word) = $message->{text} =~ /\Au (.+)\s/;
                my $text = WWW::Uncyclopedia->search($word);
                
                my $response = $text ? do {
                    my @part = split(/。/, $text);
                    my $rtn = join("。", @part[0..3]);
                    sprintf("%s\n\n%s", $rtn, WWW::Uncyclopedia->url($word));
                } : 'なんすかそれ';
                $bot->post($response, @tags);
            }
        }
    });

});

$cv->wait;


