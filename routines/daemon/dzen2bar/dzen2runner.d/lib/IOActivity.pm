package IOActivity;
use v5.36.0;
my @UNITS = qw(Bs Ks Ms Gs);
use constant KIBI => 1024;


sub _fetch_IO_update {
    my($self, $curr_stats) = @_;

    for my $dev (sort keys %{$curr_stats}) {
        my $io_loads = $self->_calc_io_loads($dev, $curr_stats);
        $self->append_tokens([ { label => $self->{device_map}{$dev} } ]);
        $self->_append_io_tokens({
            map {
                $_ => $self->to_unit_value_map({
                    load   => $io_loads->{$_},
                    l_just => ($_ eq 'out' ? 1 : 0)
                })
            } keys %$io_loads
        });
    }
    $self->{prev_stats} = $curr_stats;
}


sub to_unit_value_map {
    my($self, $arg) = @_;
    for (@UNITS) {
        ($arg->{load} >= KIBI)
          and $arg->{load} /= KIBI
          or return {
            unit  => $_,
            value =>
              sprintf '%' . ($arg->{l_just} ? '-' : '') . '3.0f'
            , $arg->{load}
          };
    }}

# returns hashref of in-& output loads averaged over configured interval
# shape: {in|out => average_load(device_id)}
sub _calc_io_loads {
    my($self, $dev_key, $curr_stats) = @_;
    return {
        map {
            $_ => (
                $curr_stats->{$dev_key}{$_}
                  - ($self->{prev_stats}{$dev_key}{$_} || 0)
            ) / $self->{interval}
        } qw(in out)
    }
}


sub _append_io_tokens {
    my($self, $disp_fmt) = @_;
    my @seps = qw([ : ] :);
    $self->append_tokens([
        map {(
            { sep   => shift @seps },
            { value => $disp_fmt->{in}{$_} },
            { sep   => shift @seps },
            { value => $disp_fmt->{out}{$_} }
        )} qw(unit value)
    ]);
}


sub _get_IO_activity {
    my($self, $callbacks) = @_;
    return {
        map {
            my $device_id = $_;
            my $line      = $callbacks->{data_loader}->($device_id);
            defined $line
              ? (
                $device_id => do {
                    my($in, $out) = $callbacks->{data_parser}->($line);
                    { in => $in, out => $out };
                }
              )
              : ()
        } sort keys %{ $self->{device_map} }
    };
}
1;
