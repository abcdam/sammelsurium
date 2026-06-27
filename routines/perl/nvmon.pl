#!/usr/bin/env perl
use v5.36.0;

use lib './lib';

use CmdGazer;

use File::Basename;
use POSIX qw(strftime);

use constant SECOND_MS  => 1e3;
use constant ANSI_RESET => "\e[H\e[2J";

my $period = shift // SECOND_MS;

## no critic (Subroutines::RequireArgUnpacking)
sub compile_config {
    map {{(
        query => shift @$_,
        scalar @$_
        ? (
            fstr => (sprintf '%-6s', shift @$_)
              . '%4d '
              . (shift @$_) // ''
          )
        : ()
    )}} @_
}

my @queries = compile_config
  [qw(temperature.gpu oven °C)],
  ['power.draw'],
  [qw(pstate power W/%s)],
  [qw(fan.speed fans %%)],
  [qw(memory.used vram MiB)];

my $gaze = CmdGazer::init(
    cmd => {
        bin  => 'nvidia-smi',
        args => [
            '--loop-ms', $period,
            '--format', join(',', qw(csv noheader nounits)),
            '--query-gpu', join ',', map {$_->{query}} @queries
        ]
    },
    parser => sub {
        return if my $offset =
          (my @stack = map {s/^\s+|\s+$//r} split ',')
          - @queries;

        for (@queries) {
            $offset++;
            push @stack,
              sprintf $_->{fstr}, splice @stack, 0, $offset
              and $offset = 0
              if exists $_->{fstr}
        }
        @stack
    },
);


my $printer = do {
    my $ftitle = (
        sprintf 'Every %.2fs: %s'
        , $period / SECOND_MS
        , basename $0, '.pl'
    ) . "%40s\n";
    my $cb = sub {
        sprintf "$ftitle",
          strftime '| %a %y/%m/%d %T'
          , localtime
    };
    sub {
        return unless @$_;
        print ANSI_RESET;
        say for $cb->(), @$_
    }
};

$printer->() while <$gaze>
