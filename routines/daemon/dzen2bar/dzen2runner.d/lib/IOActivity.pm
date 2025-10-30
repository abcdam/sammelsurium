package IOActivity;
use v5.36.0;

use constant FEATURE_LIST => qw(io_load space_used);
use constant KIBI         => 1024;

# https://www.compart.com/en/unicode/U+259D
my @SEP_UNIC = map {chr $_} (0x259D, 0x2590, 0x259F, 0x2588);
my @UNITS    = qw(Bs KiBs MiBs GiBs TiBs);
my %UNIT_2_SEP;
@UNIT_2_SEP{ @UNITS[ 1 .. $#UNITS ] } = @SEP_UNIC;


sub _setup_run_config {
    my($self, $feat_cfg_handler) = @_;

    $self->{dm} = $self->_build_device_map;

    my @remove_dm;
    while (my($dm_uid, $cfg) = each %{ $self->{dm} }) {
        my @toggled_feat = grep {$cfg->{show}{$_}} FEATURE_LIST;
        unless (@toggled_feat) {
            push @remove_dm, $dm_uid;
            next;
        }
        push @{ $self->{feature}{$_}{memberlist} //= [] }
          , $dm_uid for @toggled_feat;
        my %feat_cfg = %{
            $feat_cfg_handler->($dm_uid, { map {$_ => 1} @toggled_feat })
        };
        @{$cfg}{ keys %feat_cfg } = values %feat_cfg;
    }
    delete $self->{dm}{$_} for @remove_dm;
    return $self;
} ## end sub _setup_run_config


sub _get_shared_handlers {
    my $self = shift;
    return {
        io_load => sub {
            my($dev_id, $curr_stats) = @_;
            my $prev_cache = $self->{feature}{io_load}{prev_stats} ||= {};
            my $prev_stats = $prev_cache->{$dev_id}                ||= {};
            my $tokenized  = $self->_tokenize_averaged_io_load(
                $curr_stats,
                $prev_stats
            );
            $self->{feature}{io_load}{prev_stats}{$dev_id} = $curr_stats;
            return $tokenized;
        }
    };
}


sub _fetch_IO_update {
    my($self) = @_;
    my $tokens = $self->_tokenize_dev_activity;
    for my $dev_id (sort keys %{ $self->{dm} }) {
        my @collected_tokens;
        for my $feat (FEATURE_LIST) {
            next
              unless exists $tokens->{$feat}
              && exists $tokens->{$feat}{$dev_id};
            push @collected_tokens, $tokens->{$feat}{$dev_id};
        }
        my @joined = map {@$_, { sep => '%' }} @collected_tokens;
        pop @joined;
        $self->append_tokens([
            { label => $self->{dm}{$dev_id}{label} },
            @joined
        ]) if @joined;
    }}


# approp. unit of calc. value is derived implicitly from separator
# [0     B/s - 10B/s[     -> displayed as 000d
# [0.01KiB/s - 10KiB/s[   -> displayed as d▝dd
# [0.01MiB/s - 10MiB/s[   -> displayed as d▐dd
# [0.01GiB/s - 10GiB/s[   -> displayed as d▟dd
# [0.01TiB/s - 10TiB/s[   -> displayed as d█dd
sub _io_load_stringifier {
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


sub _tokenize_averaged_io_load {
    my($self, $curr_stats, $prev_stats) = @_;
    my($in_tkn_value, $out_tkn_value) = map {
        _io_load_stringifier($_)
      } map {
        (   $curr_stats->{$_}
              - ($prev_stats->{$_} // 0)
        ) / $self->{interval}
      } qw(in out);
    return [
        { value => $in_tkn_value },
        { sep   => ':' },
        { value => $out_tkn_value }
    ]
}


sub _tokenize_dev_activity {
    my($self) = @_;
    my %results = ();
    for my $feat (grep {exists $self->{feature}{$_}} FEATURE_LIST) {
        my $handler = $self->{handler}{$feat} or do {
            $self->{log}->warn("handler for feature '$feat' not implemented");
            next;
        };
        my @devs = @{ $self->{feature}{$feat}{memberlist} };
        @{ $results{$feat} }{@devs} =
          map {$handler->($_)} @devs;
    }
    return \%results;
}
1;
