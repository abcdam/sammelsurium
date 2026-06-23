#!/usr/bin/env perl
use v5.36.0;

use IPC::Run qw( start new_chunker timeout);
use constant SECOND_FACTOR  => 1e4;
use constant TIMEOUT_FACTOR => 10;


sub make_producer {
    my($cfg, @consumers) = @_;
    sub {
        print "\e[H\e[2J";
        say $cfg->{title};
        local $_ = shift;
        chomp;
        my($offset, @stack) = (
            scalar @consumers,
            map {s/^\s+|\s+$//r} split ','
        );
        return unless $offset-- == @stack;
        for (@consumers) {
            defined and $_->(splice @stack, 0, @stack - $offset);
            $offset--
        }
    };
}


sub configure {
    my($q, %cfg) = @_;
    my($l, $a)   = @cfg{qw(label append)};
    {
        query   => $q,
        consume => $l && do {
            my $fmt = sprintf('%-6s', $l) . '%4d ' . $a;
            sub {say sprintf $fmt, @_}
        }
    }
}

my @metric_handlers = (
    configure(
        'temperature.gpu',
        label  => 'oven',
        append => '°C',
    ),
    configure('power.draw'),
    configure(
        'pstate',
        label  => 'power',
        append => 'W/%s',
    ),
    configure(
        'fan.speed',
        label  => 'fans',
        append => '%%',
    ),
    configure(
        'memory.used',
        label  => 'vram',
        append => 'MiB',
    ),
);

my $INTERVAL_MS = shift // SECOND_FACTOR;
my $harness     = start(
    [
        'nvidia-smi',
        '--loop-ms', $INTERVAL_MS,
        '--format', join(',', qw(csv noheader nounits)),
        '--query-gpu', join ',', map {$_->{query}} @metric_handlers
    ],
    '>',
    new_chunker,
    make_producer(
        { title => sprintf("Every %.2fs\n", $INTERVAL_MS / SECOND_FACTOR) },
        map {$_->{consume}} @metric_handlers
    ),
    timeout($INTERVAL_MS * TIMEOUT_FACTOR)
);

$harness->pump
  while ($harness->pumpable)
  or $harness->finish;
