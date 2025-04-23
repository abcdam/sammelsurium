package IOActivity;
use v5.36.0;
my %UNIT_2_SEP;
my @UNITS = qw(Bs KiBs MiBs GiBs TiBs);

# https://www.compart.com/en/unicode/U+259D
my @SEP_UNIC = map {chr $_} (0x259D, 0x2590, 0x259F, 0x2588);
@UNIT_2_SEP{ @UNITS[ 1 .. $#UNITS ] } = @SEP_UNIC;
use constant KIBI => 1024;


sub _fetch_IO_update {
    my($self, $curr_stats) = @_;

    for my $dev (sort keys %{$curr_stats}) {
        my($IN_str, $OUT_str) = map {
            to_stringified_value_fmt($_)
          } @{
            $self->_calc_io_loads_averaged($dev, $curr_stats)
          }{qw(in out)};
        $self->append_tokens([
            { label => $self->{device_map}{$dev} },
            { value => $IN_str },
            { sep   => ':' },
            { value => $OUT_str }
        ]);
    }
    $self->{prev_stats} = $curr_stats;
}

# approp. unit of calc. value is derived implicitly from separator
# [0     B/s - 10B/s[     -> displayed as 000d
# [0.01KiB/s - 10KiB/s[   -> displayed as d▝dd
# [0.01MiB/s - 10MiB/s[   -> displayed as d▐dd
# [0.01GiB/s - 10GiB/s[   -> displayed as d▟dd
# [0.01TiB/s - 10TiB/s[   -> displayed as d█dd
sub to_stringified_value_fmt {
    my $load = shift;
    for (@UNITS) {
        ($load >= 10)
          and $load /= KIBI
          or return (
            sprintf '%' . (
                ! exists $UNIT_2_SEP{$_}
                ? '04d'
                : '.2f'
              )
            , $load
          ) =~ s/\./$UNIT_2_SEP{$_}/r;
    }}

# returns hashref of in-& output loads averaged over configured interval
# shape: {in|out => average_load(device_id)}
sub _calc_io_loads_averaged {
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
