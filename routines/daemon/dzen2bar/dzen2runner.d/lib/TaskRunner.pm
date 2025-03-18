package TaskRunner;
use v5.36.0;

use Carp;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use Path::Tiny;
use Try::Tiny;
my $CONFIG_FILE = "/usr/local/etc/dzen2runnerd.yml";
use lib '/usr/local/lib/dzen2runner.d/lib';
use MonoLog;
use ConfigParser;
my @OUTPUT_TOKENS = qw(sep label value);


use Time::HiRes qw(sleep);

STDOUT->autoflush(1);
my %is_implemented = map {$_ => 1} qw(
  cpu_stats
  localtime_view
  workspace_view
  lvm_stats
  memory_stats
  net_stats
  audiovol_view
);


sub init {
    my($class, $caller) = (shift, lc caller);
    my $self = { log => MonoLog::init_logger() };
    try {
        croak "Implementation for '$caller' not registered in TaskRunner."
          unless $is_implemented{$caller};
        my $CONFIG = ConfigParser->load({
            path     => $CONFIG_FILE,
            defaults => 'defaults',
            base_key => 'scraper'
        });

        (
            $self = {
                %{$self},
                %{ $CONFIG->get_param({ path => $caller }) }
              }
              // croak "Failed to get config for $caller in TaskRunner"
        )->{id} //= $caller;

        (bless $self, $class)
          ->_merge_missing_values($self, $CONFIG->get_param({ path => '.' }))
          ->_setup_token_handler;
    } catch {
        $self->{log}->error($_);
        croak "error in TaskRunner init: $_";
    };
    return $self;
} ## end sub init


sub run_loop {
    my $self = shift;
    try {do {$self->fetch_update} while $self->consume_and_sleep}
    catch {
        $self->{log}->error("$self->{id}: $_")
          and die sprintf
          '%s: %s\n'
          , $self->{id}, $_;
    }}


sub fetch_update {die 'fetch_update() must be defined in task implementation\n'}


sub consume_and_sleep {
    my $self = shift;
    say sprintf
      '%s%s',
      $self->{self_tag},
      delete $self->{buffer_out}

      and
      sleep $self->{interval};
}


sub _setup_token_handler {
    my($self) = @_;
    $self->{self_tag} = sprintf '[%s] ', $self->{id};
    my %tkn_formatter = map {
        my $tkn_id = $_;
        $tkn_id => ($tkn_id eq 'sep')
          ? sub {shift}
          : sub {
            $self->colorify_entry({
                string => shift,
                color  => $self->{color}{$tkn_id}
            })
          }
    } @OUTPUT_TOKENS;

    $self->{token_handler} = {
        map {
            my $trafo_instance = $tkn_formatter{$_};
            $_ => sub {
                ($self->{buffer_out} //= '') .= $trafo_instance->(shift);
            }
        } keys %tkn_formatter
    };
    return $self;
} ## end sub _setup_token_handler

# $token_list = [ {sep|label|value => string}, {sep|label|value => string}, {...];
sub append_tokens {
    my($self, $token_list) = @_;
    (   $self->_tkn_input_sanity_check($_)
          and $self->{token_handler}{ $_->{token_id} }
          or croak sprintf q(token '%s' does not exist), $_->{token_id}
      )->($_->{token_value}) for
      map {    # switcheroo 1<->2 to get correct hash layout
        {('token_id', 'token_value', %{$_})[ 0, 2, 1, 3 ]}
      } @{$token_list};
}


sub colorify_entry {
    my($self, $arg) = @_;
    local $self->{log}->context->{arg} = $arg;
    if (my @param =
        @{$arg}{qw(color string)}
    ) {
        croak 'Malformed  argument. Expected 2 defined k/v pairs'
          unless 2 == @param
          and
          return sprintf '^fg(%s)%s^fg()'
          , @param;
    }
    die 'No args passed to colorify_entry()\n';
}


sub _tkn_input_sanity_check {
    my($self, $input) = @_;
    if (2 == (
            my($tkn, $val) =
              @{$input}{qw(token_id token_value)}
        ))
    {   $self->{log}->warn(
            sprintf q(%s '%s:%s' %s)
            , 'Detected more than 1 token id. Proceeding with'
            , $tkn, $val
            , 'and discarding the rest'
        ) unless 2 == keys %$input;
        return 1;
    }
    die sprintf '%s %s %s\n'
      , 'Unexpected Input.'
      , 'Expected a single token_id/token_value pair but found:'
      , join ','
      , grep {! /^(token_id|token_value)$/} %{$input};
} ## end sub _tkn_input_sanity_check


sub _merge_missing_values {
    my($self, $target, $source) = @_;

    for my $key (keys %$source) {
        if (exists $target->{$key}
            && ref $target->{$key} eq 'HASH'
            && ref $source->{$key} eq 'HASH'
          )
        {$self->_merge_missing_values($target->{$key}, $source->{$key})}
        else {$target->{$key} //= $source->{$key}}
    }
    return $self;
}
1;
