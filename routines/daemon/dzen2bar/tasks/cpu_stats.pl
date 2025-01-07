#!/usr/bin/env perl
use v5.36.0;
use strict;
use warnings;
use Time::HiRes qw(sleep time);
use Carp;
BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/lib';
}
use Util qw(colorize format_section get_interval);

STDOUT->autoflush(1);

my $init=1;
my $previous_stats = format_section('Init...',undef, 'yellow');

sub run {
    my $tag = shift;

    my $interval = get_interval('cpu_stats') || 60;

    while (1) {
        my $cpu_line = _read_cpu_line();
        my @current_stats = _parse_cpu_fields($cpu_line);

        if ( ! $init) {
            my @delta = _calculate_delta(\@current_stats, $previous_stats);

            say "[$tag] " . _format_output(_calculate_percentages(@delta));
        } else {
            say "[$tag] $previous_stats";
            undef $init;
        }

        $previous_stats = \@current_stats;
        sleep($interval);
    }
}

sub _read_cpu_line {
    open my $stat_fh, '<', '/proc/stat' or die "Cannot open /proc/stat: $!";
    my $cpu_line = <$stat_fh>;
    close $stat_fh;
    return $cpu_line;
}

sub _parse_cpu_fields {
    my ($cpu_line) = @_;
    my @fields = split(/\s+/, $cpu_line);
    return @fields[1 .. 7];
}

sub _calculate_delta {
    my ($current, $previous) = @_;
    return map { $current->[$_] - $previous->[$_] } 0 .. $#{$current};
}

sub _calculate_percentages {
    my (@delta) = @_;
    my $total_time = 0;
    $total_time += $_ for @delta;

    return map { sprintf("%.1f", 100 * $_ / $total_time) } @delta;
}

sub _format_output {
    my ($user_pct, $system_pct, $idle_pct, $iowait_pct, $irq_pct, $softirq_pct) = @_;

    return join(' ',
        format_section("usr%$user_pct",     'orange'),
        format_section("sys%$system_pct",   'orange'),
        format_section("idl%$idle_pct",     'orange'),
        format_section("io%$iowait_pct",    'orange'),
        format_section("hirq%$irq_pct",     'orange'),
        format_section("sirq%$softirq_pct", 'orange'),
    );
}

if (!caller) {
    my $tag = $ARGV[0] || croak "no tag supplied.";
    run($tag);
}
