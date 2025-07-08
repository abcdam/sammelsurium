#!/usr/bin/env perl
use v5.36.0;

package Workspace_view;


BEGIN {
    use File::Basename;
    push @INC, dirname(__FILE__) . '/../lib';
}

use IPC::Run qw( start new_chunker input_avail get_more_input);
use JSON::XS;
use parent 'TaskRunner';

my @CMD
  = (qw(i3-msg -t subscribe -m), qq(["workspace"]));

my $state_buffer = {
    is_dirty  => undef,
    active_id => undef,
    id_map    => {}
};

my $fake_out;
my $event_harness = start \@CMD
  , '>'
  , new_chunker    # split by newline on multiple events
  , \&_event_handler
  , \$fake_out;


END {
    if ($event_harness->pumpable) {
        $event_harness->finish and sleep 5
          or $event_harness->kill_kill
          or warn "harness cleanup failed: $@";
    }}


sub _event_handler {
    my($in_ref, $out_ref) = @_;

    # https://metacpan.org/pod/IPC::Run#input_avail
    my $maybe_input = input_avail;
    return 0 unless
      defined $maybe_input
      && ! length $$out_ref;

    do {
        my $raw_event = $$in_ref;

        # clear input: https://metacpan.org/pod/IPC::Run#new_chunker
        $$in_ref = '';
        my $event = decode_json($raw_event)
          or return 0;    # NOTE: might need verbose err handling

        my $change_type = $event->{change}
          or return 0;
        my $updated_id = $event->{current}{name};
        if ($change_type eq 'focus') {
            if ($updated_id ne $state_buffer->{active_id}) {
                @{$state_buffer}{qw(active_id is_dirty)} = ($updated_id, 1);
                $state_buffer->{id_map}{$updated_id} = 1;
            }}
        elsif ($change_type eq 'empty') {
            delete $state_buffer->{id_map}{$updated_id};
            $state_buffer->{is_dirty} = 1;
        }

        # https://metacpan.org/pod/IPC::Run#get_more_input
        $maybe_input = get_more_input;
    } while (
        defined $maybe_input
        && $maybe_input ne 0
    );
    return 0;
} ## end sub _event_handler


sub _get_workspace_tokens {
    return map {{
        (   $_ eq $state_buffer->{active_id}
            ? 'value'
            : 'label'
        ) => sprintf('%s ', $_)
    }} sort keys %{ $state_buffer->{id_map} };
}


sub _init_state {
    my $self    = shift;
    my @wspaces = @{ decode_json(`i3-msg -t get_workspaces`) };
    for (@wspaces) {
        @{$state_buffer}{qw(active_id is_dirty)}
          = ($_->{name}, 1) if $_->{focused};
        $state_buffer->{id_map}{ $_->{name} } = 1;
    }
    return $self;
}


sub fetch_update {
    my($self) = @_;
    return unless $event_harness->pumpable;
    $event_harness->pump_nb;    # https://metacpan.org/pod/IPC::Run#pump_nb
    if ($state_buffer->{is_dirty}) {
        $self->append_tokens([
            { label => 'workspace' },
            { sep   => ': ' },
            _get_workspace_tokens()
        ]);
        delete $state_buffer->{is_dirty};
    }}


sub run {
    my $class = shift;
    $class->init->_init_state->run_loop;
}


package main;
Workspace_view->run;
