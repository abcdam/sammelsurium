
#!/usr/bin/perl
use strict;
use warnings;
use Rex -feature => ['1.4'];
use Rex::Resource::firewall;
use Rex::Commands::connection;
use IPC::Run qw(run);

# TODO: objectify qube dependent logic
my $vault_qube = "secrets-vault"; # move to config definition file
my $disposable_firewall_vm = "secrets-fw-dvm"; # same
my $router_vm = "com-coordinator"; #same
my $firewall_rules_file = "/tmp/dynamic_firewall_rules.out";  # File to store generated firewall rules
my $logs = "/var/log/generated-iptables.log";


# each gatekeeper obj is responsible for construction of an ultra short term comm window and a semi-dynamic route from secure enclave 
#   into the web for sync based ops before tearing it all down
#
# base case tresor layout for all applications interfacing with  OSI8:   
#
#	 
#				
#	AppVM ------> disposable FW guard --------> central coordinator ------------> system wide FW ---------------> sys-net VM
#         ^                    ^                             ^                              ^                             ^
#    opcrit data      short-lived micro FW in-	   dynamically opens ports	      last frontier,		       wild west		
#   99.99% offline     stances, dynamic out-        to consume and forward           minimal port set
#		       port, static inport,         requests. Default case:	  # open, accepts reqs
#			per app basis	             All ports closed <-->	      from coord. only
sub Gatekeeper {
    my ($class, $config_path) = @_;
    
    my $self = {
	cfg_path => $config_path
    };
    return bless $self, $class;
}


sub synchronize {
    my ($self) = @_;
    
    $self->spin_up_fw();

    
    my $cmd = "qvm-run --pass-io $self->{secrets-fw-dvm} '/bin/bash -c \"/bin/iptables-restore < $self->{secrets-fw-dvm-file}\"'";
    my $output = run $cmd, "2>&1", $logs;

    #TODO: open corresponding port  in system wide communication coordinator
    say $output;

    $self->dispose_fw();
}


sub spin_up_fw {
    my ($self) = @_;
    say "Opening gate to router at: $self->{secrets-fw-dvm}";
    Rex::Commands::run("qvm-start $self->{secrets-fw-dvm-id}");
    # TODO: wait for confirmation of connection
}

# Function to stop the Disposable Firewall VM
sub dispose_fw {
    my ($self) = @_;
    say "Stopping $self->{secrets-fw-dvm-id}: $self->{secrets-fw-dvm}";
    Rex::Commands::run("qvm-stop $self->{secrets-fw-dvm}");
    
}

sub assemble_fw_rules {
    my ($self) = @_;
    my $firewall = Rex::Resource::firewall->new();

    # disposable fw
    $firewall->open(
        sport   => $self->{static_port_lhs_listen},
        source => $self->{AppVM} # vault -> fw
	proto  => 'tcp',
        action => 'accept',
	dport => $self->{dynamic_port_rhs_transmit},
	destination => $self->{com_coordinator}
    );
    
    # coordinator/orchestrator
    $firewall->open(
	sport => $self->{dynamic_port_rhs_transmit} 
        dport => $self->{static_port_rhs_transmit_exclusive},
        proto => 'tcp',
        to => $self->{sysnet_fw_interface}
    );
	

    # $firewall->flush_rules();
    # $firewall->commit();

    # 
    say "Dumping generated firewall rules...";
    my ($file1_fp, $file1,  $file2_fp, $file2) = (); # TODO: split up fw definition
    use Data::Dumper qw(Dumper)
    use File::Slurper wq(write_text);
    $self->{secrets_fw_dvm_file} = $file1_fp;
    write_text $file1_fp, Dumper $file1;
    
    $self->{com_coordinator_file} = $file2_fp
    write_text $file2_fp, Dumper $file2;
}

sub copy_fw_rules {
    my ($self) = @_;

    say "Copying firewall rules file to $self->{secrets_fw_dvm_id}...";
    Rex::Commands::run("qvm-copy $self->{secrets_fw_dvm_id} $self->{secrets_fw_dvm_file}");
    say "Copying firewall rules file to $self->{com_coordinator_id}...";
    Rex::Commands::run("qvm-copy $self->{com_coordinator_id} $self->{com_coordinator_file}");
}
###############################################
# TODO: Objectify this logic -> create parent to invoke
say "generating and synchronizing firewall rules...";
assemble_rules();

# Copy generated firewall rules file to relevant VMs
copy_firewall_rules($vault_qube);
copy_firewall_rules($disposable_firewall_vm);
copy_firewall_rules($router_vm);

# Synchronize Vault Qube
synchronize_vault();
say "Synchronization completed.";




