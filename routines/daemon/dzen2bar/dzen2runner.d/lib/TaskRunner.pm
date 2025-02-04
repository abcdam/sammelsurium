package TaskRunner;
use v5.36.0;

use Carp;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use Path::Tiny;
use YAML::Tiny qw(LoadFile);

my $CONFIG_DIR="/usr/local/etc/dzen2runnerd.yml";
my $CONF = LoadFile($CONFIG_DIR)
    or croak ("couldn't load config @ $CONFIG_DIR");
use Time::HiRes qw(sleep);

STDOUT->autoflush(1);
my %is_implemented = map { $_ => 1 }
    qw(
        cpu_stats
        localtime_view
        workspace_view
        lvm_stats
        memory_stats
        wifi_stats
    );

sub init {
    my ($class, %args) = @_;
    my ($pkg) = caller;
    my $caller = lc $pkg;
    croak "Implementation for '$caller' not registered in TaskRunner."
        unless $is_implemented{$caller};
    (my $self = $CONF->{$caller})
        or croak "No config entry found for '$caller' in config";
    $self->{id} //= $caller;
    _merge_missing_values($self, $CONF->{global}{default});
    bless $self, $class;
    return $self;
}

sub run_loop {
    my $self = shift;

    while (1) {
        say "[$self->{id}] " . $self->get_update;
        sleep($self->{interval});
    }
}

sub get_update {
    croak("'get_update' must be defined in task implementation");
}

sub colorify_entry {
    my ($self, $string, $color_h)= @_;
    croak "missing argument. Expected 2, found string: '$string', color: '$color_h'"
        unless $string && $color_h;
    return sprintf "^fg(%s)%s^fg()", $color_h, $string;
}
sub _merge_missing_values {
    my ($target, $source) = @_;
    for my $key (keys %$source) {
        if (exists $target->{$key} && ref $target->{$key} eq 'HASH' && ref $source->{$key} eq 'HASH') {
            _merge_missing_values($target->{$key}, $source->{$key});
        } else {
            $target->{$key} //= $source->{$key};
        }
    }
}
1;
