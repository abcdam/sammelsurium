package IOActivity;
use v5.36.0;
my @UNITS = qw(Bs Ks Ms Gs);
use constant KIBI => 1024;


sub fetch_IO_update {
    my($self, $curr_stats) = @_;

    for my $dev (sort keys %{$curr_stats}) {
        my($r_load, $w_load)
          = $self->_calc_rw_loads($dev, $curr_stats);

        my %disp_fmt = (
            r => $self->to_unit_value_map({ load => $r_load, l_justed => 0 }),
            w => $self->to_unit_value_map({ load => $w_load, l_justed => 1 }),
        );
        $self->append_tokens(
            [ { label => $self->{device_map}{$dev} } ]);
        $self->_append_read_write_tokens(\%disp_fmt);
    }
    $self->{prev_stats} = $curr_stats;
}


sub to_unit_value_map {
    my($self, $arg) = @_;
    for (@UNITS) {
        if ($arg->{load} >= KIBI) {
            $arg->{load} /= KIBI;
            next;
        }
        return {
            unit  => $_,
            value => sprintf '%'
              . ($arg->{l_justed} ? '-' : '')
              . "3.0f"
            , $arg->{load}
        };
    }
}


sub _calc_rw_loads {
    my($self, $vol_key, $curr_stats) = @_;
    map {
        (   $curr_stats->{$vol_key}{$_}
              - ($self->{prev_stats}{$vol_key}{$_} || 0))
          / $self->{interval}
    } qw(r w);
}


sub _append_read_write_tokens {
    my($self, $disp_fmt) = @_;
    my @seps = qw([ : ] :);
    $self->append_tokens([
        map {(
            { sep   => shift @seps },
            { value => $disp_fmt->{r}{$_} },
            { sep   => shift @seps },
            { value => $disp_fmt->{w}{$_} }
        )} qw(unit value)
    ]);
}


sub _get_activity {
    my($self, $callbacks) = @_;
    return {
        map {
            my $device_id = $_;
            my $line      = $callbacks->{data_loader}->($device_id);
            defined $device_id
              ?
              ( $device_id => do
                {   my($r, $w) = $callbacks->{data_parser}->($line);
                    { r => $r, w => $w };
                }
              )
              : ()
        } sort keys %{ $self->{device_map} }
    };
}
1;
