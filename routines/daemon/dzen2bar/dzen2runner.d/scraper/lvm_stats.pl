#!/usr/bin/env perl
use v5.36.0;
package Lvm_stats;

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

    my %current_stats = $self->_get_lvm_activity;
    my @output;

    for my $vol (sort keys %current_stats) {
        my ($reads, $writes) = @{$current_stats{$vol}};
        my ($prev_read, $prev_write) = @{$self->{prev_stats}{$vol} || [0, 0]};

        my ($r_speed, $r_unit) = $self->_format_speed(($reads - $prev_read) / $self->{interval});
        my ($w_speed, $w_unit) = $self->_format_speed(($writes - $prev_write) / $self->{interval}, 1);

        my @results = ($self->colorify_entry($vol, $self->{color}{label}));
        push @results, map {
            $self->colorify_entry($_, $self->{color}{value})
        } ($r_unit, $w_unit, $r_speed, $w_speed);
        push @output, sprintf "%s[%s:%s]%s:%s", @results;
    }
    $self->{prev_stats} = \%current_stats;
    return join('', @output);
}

sub _get_lvm_activity {
    my ($self) = @_;
    my %stats = map {
        my ($line) = Path::Tiny::path("/sys/block/$_/stat")->lines;
        my @fields = grep { /\d+/ } split ' ', $line;
        $self->{dm_map}{$_} => [$fields[0], $fields[4]];
    } keys %{$self->{dm_map}};
    return %stats;
}

sub _format_speed {
    my ($self, $bytes, $justify_left) = @_;
    $justify_left = $justify_left ? '-' : '';
    my $unit;
    my $G = 1073741824; # 1024^3
    my $M = 1048576;
    my $K = 1024;

    if ($bytes < $K) { 
        $unit = 'Bs';
    } elsif ($bytes < $M) {
        $bytes /= $K;
        $unit = 'Ks';
    } elsif ($bytes < $G) {
        $bytes /= $M;
        $unit = 'Ms';
    } else {
        $bytes /= $G;
        $unit = 'Gs';
    }
    return (sprintf("%${justify_left}3.0f", $bytes), $unit);
}

package main;
Lvm_stats->run;