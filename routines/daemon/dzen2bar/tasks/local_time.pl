#!/usr/bin/env perl
use v5.36.0;
use strict;
use warnings;
use Carp;
use Time::HiRes qw(sleep);
BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/lib';
}
use Util qw(format_section get_interval);
STDOUT->autoflush(1);

sub run {
    my $tag = shift;
    my $interval = get_interval('local_time') || 1;

    while (1) {
        say "[$tag] " . format_section(_get_formatted_time(), 'soft_olive');
        sleep($interval);
    }
}

sub _get_formatted_time {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime();
    my @days = qw(Sun Mon Tue Wed Thu Fri Sat);

    # Format: Day HH:MM:SS MM/DD
    return sprintf(
        "%s %02d:%02d:%02d %02d/%02d",
        $days[$wday],
        $hour,
        $min,
        $sec,
        $mon + 1,
        $mday,
    );
}

if (!caller) {
    my $tag = $ARGV[0] || croak "no tag supplied.";
    run($tag);
}