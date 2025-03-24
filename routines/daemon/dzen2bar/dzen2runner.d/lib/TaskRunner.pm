package TaskRunner;
use v5.36.0;

use Carp;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use Path::Tiny;
use Try::Tiny;

use constant CONFIG_f_PATH => "/usr/local/etc/dzen2runnerd.yml";
use constant LIB_DIR       => '/usr/local/lib/dzen2runner.d/lib';
use lib LIB_DIR;

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
    croak "Implementation for '$caller' not registered in TaskRunner."
      unless $is_implemented{$caller};
    my $id   = $caller;
    my $self = { log => MonoLog::init_logger({ tag => $id }) };
    try {
        my $conf_handler = ConfigParser->load({
            path     => CONFIG_f_PATH,
            defaults => 'defaults',
            base_key => 'scraper'
        });
        (
            $self = {
                %{$self},
                %{ $conf_handler->get_param({ path => $id }) }
              }
              // croak "Failed to get config for '$id' in TaskRunner"
        )->{id} //= $id;
        my $conf_defaults = $conf_handler->get_param({ path => '.' });
        (bless $self, $class)
          ->_supplement_missing_configs($self, $conf_defaults)
          ->_setup_token_handler;
    } catch {
        my $m = "TaskRunner init failed: $_";
        _logErr($self, $m) and die $m;
    };

    return $self;
} ## end sub init


sub run_loop {
    my $self = shift;
    try {do {$self->fetch_update} while $self->consume_and_sleep}
    catch {my $m = $_; $self->{log}->error($m) and die $m}
}


sub fetch_update {die 'fetch_update() must be defined in task implementation\n'}


sub consume_and_sleep {
    my $self = shift;
    say sprintf
      '%s%s',
      $self->{self_tag},
      delete $self->{buffer_out}

      and sleep $self->{interval};
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
          and $self->{token_handler}{ $_->{token_id} } or do {
            my $m = "token '$_->{token_id}' is not valid";
            $self->_logErr($m, $token_list) and die $m;
          }
    )->($_->{token_value}) for map {

        # switcheroo 1<->2 to get correct hash layout
        {('token_id', 'token_value', %{$_})[ 0, 2, 1, 3 ]}
    } @{$token_list};
}


sub colorify_entry {
    my($self, $arg) = @_;
    my @params = @{$arg}{qw(color string)};
    unless (2 == grep {defined} @params) {
        my $m = q(Expected defined values for 'color' and 'string');
        $self->_logErr($m, $arg) and die $m;
    }
    return sprintf '^fg(%s)%s^fg()'
      , @params;
}


sub _tkn_input_sanity_check {
    my($self, $input) = @_;
    my @tkn_id_val = @{$input}{qw(token_id token_value)};
    if (2 == grep {defined} @tkn_id_val) {
        $self->{log}->warn(
            sprintf q(%s '%s:%s' %s)
            , 'Detected more than 1 token id. Proceeding with'
            , @tkn_id_val
            , 'and discarding the rest'
        ) unless 2 == keys %{$input};
        return 1 == 1;
    }
    my $m = 'Expected a single id/value pair after token normalization';
    $self->_logErr($m, $input) and die $m;
}


sub _supplement_missing_configs {
    my($self, $target, $source) = @_;

    for my $key (keys %$source) {
        if (exists $target->{$key}
            && ref $target->{$key} eq 'HASH'
            && ref $source->{$key} eq 'HASH'
          )
        {$self->_supplement_missing_configs($target->{$key}, $source->{$key})}
        else {$target->{$key} //= $source->{$key}}
    }
    return $self;
}


sub _logErr {
    my($self, $msg, $ctxt) = @_;
    local $self->{log}->context->{ctxt} = $ctxt
      unless ! $ctxt;
    $self->{log}->error($msg);
}
1;
