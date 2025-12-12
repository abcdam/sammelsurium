#!/bin/env perl
use v5.36;
use IPC::Cmd qw(can_run run);
use Time::Duration;
use List::Util qw (max);
use Term::ANSIColor;

my @FIELDS = qw(committerdate:unix refname:short subject);

my $util = {
    create_time_since =>
      sub {my $now = time(); sub {concise(ago($now - shift))}},
    create_line_formatter => sub {
        my $len_tuple = shift;
        my $idx_last  = $#$len_tuple;
        my @align     = ('', ('-') x $idx_last);
        my @patterns
          = map {sprintf '%%%s%ds', $align[$_], $len_tuple->[$_]}
          0 .. $idx_last;
        my @colors = (['blue'], ['bright_yellow'], ['white']);
        sub {
            my $list        = shift;
            my $idx_last    = $#$list;
            my @out_partial = map {
                colored($colors[$_], sprintf $patterns[$_], $list->[$_])
            } 0 .. $idx_last;
            join '  ', @out_partial
        }}
};


sub run_git {
    my($git_bin, $fields) = @_;
    my $cmd = [
        $git_bin, 'for-each-ref',
        '--sort=-committerdate',
        "--format=" . join('%00', map {"%($_)"} @$fields),
        'refs/heads/'
    ];
    my($succ, $err, $full, $stdout, $stderr) = run(command => $cmd);
    my $value = $succ ? $stdout->[0] : $stderr->[0];
    return $succ, $value;
}


sub preproc_data {
    my($raw, $cols_count) = @_;
    my $time_passed        = $util->{create_time_since}->();
    my @max_length_tracker = (0) x $cols_count;
    my @lines;
    for (split '\n', $raw) {
        my @partials = (split /\0/, $_, $cols_count);
        $partials[0] = $time_passed->($partials[0]);
        @max_length_tracker
          = map {max($max_length_tracker[$_], length $partials[$_])}
          0 .. $#partials;
        push @lines, \@partials;
    }
    {   lines    => \@lines,
        line_fmt => $util->{create_line_formatter}->(\@max_length_tracker)
    }
}


sub to_formatted_out {
    my @preproc_args = @_;
    my($lines, $line_fmt) = @{
        preproc_data(@preproc_args)
    }{qw(lines line_fmt)};
    join "\n", map {$line_fmt->($_)} @$lines;
}

my $bin_path = can_run('git')
  or die 'git is not installed';

my($ok, $out) = run_git($bin_path, \@FIELDS);
die $out unless $ok;

my $cols_count = @FIELDS;
say to_formatted_out($out, $cols_count);
