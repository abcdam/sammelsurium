#!/usr/bin/env perl
use v5.36.0;

package Wifi_stats;
BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}
use parent 'TaskRunner';


sub run {
    my $class = shift;
    $class->init->run_loop;
}

sub get_update {
    my ($self) = @_;

    my ($prev_rx, $prev_tx) = @{$self->{prev_stats} || [$self->_get_wifi_bytes()]};
    my ($current_rx, $current_tx) = $self->_get_wifi_bytes();

    my $rx_speed = ($current_rx - $prev_rx) / $self->{interval};
    my $tx_speed = ($current_tx - $prev_tx) / $self->{interval};

    my ($rx_formatted, $rx_unit) = $self->_format_speed($rx_speed);
    my ($tx_formatted, $tx_unit) = $self->_format_speed($tx_speed, 1);

    my $d_label = $self->colorify_entry($rx_unit, $self->{color}{value});
    my $u_label = $self->colorify_entry($tx_unit, $self->{color}{value});
    my $rx_value = $self->colorify_entry($rx_formatted, $self->{color}{value});
    my $tx_value = $self->colorify_entry($tx_formatted, $self->{color}{value});

    $self->{prev_stats} = [$current_rx, $current_tx];

    return sprintf "%s/%s[$d_label:$u_label]$rx_value:$tx_value ", 
            $self->colorify_entry("d", $self->{color}{label}),
            $self->colorify_entry("u", $self->{color}{label});
}

sub _get_wifi_bytes {
    my ($self) = @_;
    my $interface = $self->{interface};

    open my $net_dev_fh, '<', '/proc/net/dev' or die "Cannot open /proc/net/dev: $!";
    while (<$net_dev_fh>) {
        if (/^\s*\Q$interface\E:\s*(\d+)(?:\s+\d+){7}\s+(\d+)/) {
            close $net_dev_fh;
            return ($1, $2);
        }
    }
    close $net_dev_fh;
    return (0, 0);
}

sub _format_speed {
    my ($self, $bytes, $justify_left) = @_;
    $justify_left = $justify_left ? '-' : '';
    my $unit;
    my $M = 1048576;
    my $K = 1024;
    if ($bytes < $K) { 
        $unit = 'Bs';
    } elsif ($bytes < $M) {
        $bytes /= $K;
        $unit = 'Ks';
    } else {
        $bytes /= $M;
        $unit = 'Ms';
    }
    return sprintf("%${justify_left}3.0f", $bytes), $unit;
}

package main;
Wifi_stats->run;