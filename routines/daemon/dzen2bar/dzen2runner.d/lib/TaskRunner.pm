package TaskRunner;
use v5.36.0;

use Carp;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use YAML::Tiny qw(LoadFile);
use Path::Tiny;
use Try::Tiny;
my $CONFIG_FILE = "/usr/local/etc/dzen2runnerd.yml";
use lib '/usr/local/lib/dzen2runner.d/lib';
use ConfigParser;
my @OUTPUT_TOKENS = qw(sep label value);

my $CONFIG = ConfigParser->load(
    $CONFIG_FILE,
    defaults => 'defaults',
    base_key => 'scraper'
) or croak "couldn't load config @ $CONFIG_FILE";

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

    (
        my $self = $CONFIG->get_param({ path => $caller })
          or croak "Failed to get config for $caller in TaskRunner"
    )->{id} //= $caller;

    return (
        bless $self, $class
    )->_merge_missing_values(
        $self, $CONFIG->get_param({ path => '.' })
    )->_setup_token_handler;
}


sub run_loop {
    my $self = shift;

    try {
        do {$self->fetch_update}
          while $self->consume_and_sleep;
    } catch {
        say STDERR sprintf
          '%s%s',
          $self->{self_tag},
          $self->colorify_entry({
            string => "ERROR: $_",
            color  => '#ffffff'
          });
        sleep 360;
    }
}


sub fetch_update {
    croak("'fetch_update' must be defined in task implementation");
}


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
    my %tkn_processors = map {
        my $trafo_id = $_;
        $trafo_id => ($trafo_id eq 'sep')
          ? sub {shift}
          : sub {
            $self->colorify_entry({
                string => shift,
                color  => $self->{color}{$trafo_id}
            });
          }
    } @OUTPUT_TOKENS;

    $self->{token_handler} = {
        map {
            my $trafo_instance = $tkn_processors{$_};
            $_ => sub {
                ($self->{buffer_out} //= '') .= $trafo_instance->(shift);
            }
        } keys %tkn_processors
    };
    return $self;
} ## end sub _setup_token_handler

# $token_list = [ {sep|label|value => string}, {sep|label|value => string}, {...];
sub append_tokens {
    my($self, $token_list) = @_;

    (    ## start inline error handling
        keys %{$_} != 2
          && croak sprintf
          'multiple token ids ( %s ) supplied by (%s) but only one of <%s> expected'
        , (join ',', keys %{$_})
        , $self->{id}
        , (join '|', @OUTPUT_TOKENS) or
          ## end inline error handling

          $self->{token_handler}{ $_->{token_id} }
          or croak "token '$_->{token_id}' does not exist"
    )->($_->{token_value}) for map {{

        # switcheroo 1<->2 to get correct hash layout
        ('token_id', 'token_value', %{$_})[ 0, 2, 1, 3 ]
    }} @{$token_list};
} ## end sub append_tokens


sub colorify_entry {
    my($self, $arg) = @_;

    my($str, $col) = @{$arg}{qw(string color)}
      or croak sprintf
      q(missing argument. Expected 2, found string: '%s', color: '%s')
      , $arg->{string} || 'UNDEF', $arg->{color} || 'UNDEF';

    return sprintf '^fg(%s)%s^fg()'
      , $col, $str;
}


sub _merge_missing_values {
    my($self, $target, $source) = @_;

    #print Dumper $self;
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
