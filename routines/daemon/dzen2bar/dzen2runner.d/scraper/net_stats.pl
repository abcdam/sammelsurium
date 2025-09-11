#!/usr/bin/env perl
use v5.36.0;

package Net_stats;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}

use parent qw(TaskRunner IOActivity);


sub _build_device_map {
    my $self = shift;
    while (my($dev_cfg_key, $cfg) = each %{ $self->{device_conf} }) {
        $cfg->{dev_cfg_key} = $dev_cfg_key;
    }
    return $self->{device_conf};
}


sub _rxtx_paths {
    my $iface           = shift;
    my $iface_stat_path = sprintf '/sys/class/net/%s/statistics', $iface;
    return {
        map {
            my $id = $_ . '_bytes';
            $id => sprintf '%s/%s'
              , $iface_stat_path
              , $id
        } qw(rx tx)
    }
}


sub run {
    my $class = shift;
    $class
      ->init
      ->_register_handlers
      ->_setup_run_config(sub {
        my($interface, $toggles) = @_;
        return {
            $toggles->{io_load} ? (paths => _rxtx_paths($interface)) : (),
        }
      })->run_loop;
}


sub fetch_update {(shift)->_fetch_IO_update}


sub _load_rxtx_bytes {
    my $path = shift;
    return sprintf '%d', Path::Tiny::path($path)->lines;
}


sub _get_current_stats {
    my($self, $interface) = @_;
    my $paths = $self->{dm}{$interface}{paths};
    my $data  = {
        map {
            my $id = $_ . '_bytes';
            $id => _load_rxtx_bytes($paths->{$id})
        } qw (rx tx)
    };
    my %curr_stats;
    @curr_stats{qw(in out)} = map {$data->{ $_ . '_bytes' }} qw (rx tx);
    return \%curr_stats;
}


sub _register_handlers {
    my $self            = shift;
    my $shared_handlers = $self->_get_shared_handlers;
    my $handler         = {
        io_load => sub {
            my($dev_id) = @_;
            my $curr = $self->_get_current_stats($dev_id);
            return $shared_handlers->{io_load}->($dev_id, $curr);
        },
    };

    $self->{handler} = $handler;
    return $self;
}

package main;
Net_stats->run;
