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
use Time::Out qw(timeout);

$WWW::Uncyclopedia::BASE_URL = 'http://xn--cckacd9c8a6ing0g5b.com/';
$WWW::Uncyclopedia::TIMEOUT = 4;
our $TIMEOUT = 4;

my $bot_name = $ENV{BOT_NAME} || '物笑い君';
my @tags = qw/PUBLIC/;

my $bot = Unruly->new(
    url  => $ENV{YANCHA_URL} || 'http://yancha.hachiojipm.org',
    tags => {map {($_ => 1)} @tags},
    ping_intervals => 15,
);

unless( $bot->login($bot_name) ) {
    critf('Login failure');
    exit;
}

my $cv = AnyEvent->condvar;

sub trim_text {
    my $text = shift;
    my @part = split(/。/, $text);
    join("。", @part[0..3]);
}

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
                if($word) {
                    my $text; 
                    timeout $TIMEOUT => sub { 
                        $text = WWW::Uncyclopedia->search($word);
                    };
                    
                    my $response = $text ? 
                        sprintf( "%s\n\n%s", trim_text($text), WWW::Uncyclopedia->url($word) ) :
                        sprintf( "%sについては不明だが、%s\n", $word, trim_text(WWW::Uncyclopedia->search('特別:おまかせ表示')) )
                    ;

                    $bot->post($response, @tags);
                }
            }
        }
    });

});

$cv->wait;


