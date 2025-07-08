#!/usr/bin/env perl
use v5.36.0;

package Net_stats;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}

use parent qw(TaskRunner IOActivity);


sub _build_interface_map {
    my $self = shift;
    while (my($dev_cfg_key, $cfg) = each %{ $self->{device_conf} }) {
        $cfg->{dev_cfg_key} = $dev_cfg_key;
    }
    return $self->{device_conf};
}


sub run {
    my $class = shift;
    my $self  = $class->init;
    $self->{dm} = $self->_build_interface_map;

    my $show_opt = [qw(io_load)];
    $self->{dm_lists} = { map {$_ => []} @$show_opt };
    while (my($dm_path, $cfg) = each %{ $self->{dm} }) {
        for (@$show_opt) {
            push @{ $self->{dm_lists}{$_} }, $dm_path
              if $cfg->{show}{$_}
        }}

    $self->run_loop;
}


sub fetch_update {
    my($self) = @_;

    my $curr_stats = $self->_get_net_activity;
    $self->_fetch_IO_update($curr_stats);
}


sub _get_net_activity {
    my($self) = @_;
    my @content = Path::Tiny::path('/proc/net/dev')->lines;
    return $self->_get_IO_activity({
        data_loader => sub {
            my $iface_dev = shift;
            my($line) = grep {/$iface_dev/} @content;
            return $line;
        },
        data_parser => sub {
            return (grep {length} split /\s+/, shift)[ 1, 9 ];
        }
    });
}

package main;
Net_stats->run;
