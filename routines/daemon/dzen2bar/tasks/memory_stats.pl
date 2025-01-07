#!/usr/bin/env perl
use v5.36.0;
use strict;
use warnings;
use Time::HiRes qw(sleep);

BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/lib';
}
use Carp;
use Util qw(format_section get_interval);

STDOUT->autoflush(1);
sub run {
    my($tag, $interval) = @_; 
    while (1) {
        my %mem = _read_meminfo();
        my $total = $mem{MemTotal};
        my $used = $mem{MemTotal} - $mem{MemFree} - $mem{Buffers} - $mem{Cached};
        my $usage_pct = sprintf("%.1f", 100 * $used / $total);
        say "[$tag] " . format_section("Mem%$usage_pct", 'smooth_yellow');
        sleep $interval;
    }
}

sub _read_meminfo {
    open my $meminfo_fh, '<', '/proc/meminfo' or die "Cannot open /proc/meminfo: $!";
    my %mem;
    while (<$meminfo_fh>) {
        $mem{$1} = $2 if /^(\w+):\s+(\d+)/;
    }
    close $meminfo_fh;
    return %mem;
}

if (!caller) {
    my $tag = $ARGV[0] || croak "no tag supplied.";
    run($tag, get_interval('memory_stats') // 1);
}