package MonoLog;
use v5.36.0;
use Carp;

use Log::Any qw($log);
use Log::Any::Adapter;

use File::Basename;
use Exporter 'import';
our @EXPORT_OK = qw($log);

my %LEVELS            = map {$_ => $_} qw(debug info warn error);
my %ADAPTER_2_OPT_REG = (
    syslog => {
        no_delay => 'ndelay',
        show_pid => 'pid',
    },
);

# adapter keys in %ADAPTER_2_OPT_REG must implement _assemble_<adapter_key>_config() handler
my %IS_IMPLEMENTED = map {$_ => 1} keys %ADAPTER_2_OPT_REG;


sub _shared_adapter_config {
    my $setup_hash = shift;
    my $base_setup = {
        name      => $setup_hash->{tag} // basename($0),
        log_level => (
            $ENV{LOG_LVL}
            ? $LEVELS{ $ENV{LOG_LVL} }
            : $LEVELS{ $setup_hash->{level} // 'info' }
        ) // 'debug',
    };
    $base_setup->{name} = sprintf '%s[%s]'
      , $base_setup->{name}
      , uc $base_setup->{log_level};

    my %adapter_opts = %{ $setup_hash->{adapter_opt} // {} };
    return \%adapter_opts, $base_setup;
}


sub _assemble_syslog_config {
    my($opt_hash, $base_setup) = _shared_adapter_config(shift);
    $base_setup->{facility} = delete($opt_hash->{facility}) // 'local0';
    my @syslog_opts = grep {defined}
      @{ $ADAPTER_2_OPT_REG{syslog} }{ keys %{$opt_hash} };
    push @syslog_opts, $ADAPTER_2_OPT_REG{syslog}{show_pid}
      if @syslog_opts == 0;
    $base_setup->{option} = join ',', @syslog_opts;
    return { %{$base_setup}{qw(name log_level facility option)} };
}

## all input optional:
#   adapter (default: syslog): a supported adapter id.
#   tag (default: basename of caller): log producer identifier
#   level (default: info): one of 'debug, info, warn, error'. A defined LOG_LVL env var has higher priority.
#   adapter_opt: a hashref of options specific to the adapter
sub init_logger {
    my($config) = @_;
    my %setup = %{$config}{qw(adapter tag level adapter_opt)};
    croak 'if set, adapter options must be passed as a hash ref'
      if defined $setup{adapter_opt} && ref $setup{adapter_opt} ne 'HASH';

    my $adapter = $setup{adapter} ? lc delete $setup{adapter} : 'syslog';
    croak "Unsupported adapter '$config->{adapter}'"
      unless $IS_IMPLEMENTED{$adapter};

    my $populated_conf_href;
    {
        no strict 'refs'; # dynamic fun selection to reduce control flow clutter
        $populated_conf_href = "_assemble_${adapter}_config"->(\%setup);
    }


    Log::Any::Adapter->set(
        ucfirst $adapter,
        %{$populated_conf_href}
    );

    $log = Log::Any->get_logger();

    if ($log->is_debug) {
        local $log->context->{logger_config} = $populated_conf_href;
        $log->debug("Instantiated logger '$adapter'");
    }
    return $log;
} ## end sub init_logger

1;
