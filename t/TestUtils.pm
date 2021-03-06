package TestUtils;

=head1 NAME

TestUtils

=head1 DESCRIPTION

Various utilities to reduce code duplication in testing.

=cut

use strict;
use warnings;
use diagnostics;

use lib '/usr/local/pf/lib';
use File::Find;
use FindBin qw($Bin);

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT_OK );
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(
        @cli_tests @compile_tests @dao_tests @integration_tests @quality_tests @quality_failing_tests @unit_tests
        use_test_db
        get_all_perl_binaries get_all_perl_cgi get_all_perl_modules
        get_networkdevices_modules get_networkdevices_classes
    );
}
use pf::config qw(%Config);

# Tests are categorized here
our @cli_tests = qw(
    pfcmd.t pfcmd_vlan.t pfdhcplistener.t
);

our @compile_tests = qw(
    pf.t pfappserver_libs.t captive-portal_libs.t template.t
);

our @dao_tests = qw(
    dao/data.t dao/graph.t dao/node.t dao/os.t dao/person.t dao/report.t
);

our @integration_tests = qw(
    integration.t integration/captive-portal.t integration/pfcmd.t integration/Portal.t integration/radius.t
);

our @quality_tests = qw(
    coding-style.t i18n.t
);

our @quality_failing_tests = qw(
    critic.t podCoverage.t
);

our @unit_tests = qw(
    config.t enforcement.t floatingdevice.t hardware-snmp-objects.t import.t inline.t linux.t network-devices/cisco.t
    network-devices/roles.t network-devices/threecom.t network-devices/wireless.t nodecategory.t person.t pfsetvlan.t
    Portal.t radius.t services.t SNMP.t SwitchFactory.t useragent.t util.t util-dhcp.t util-radius.t
    role.t web.t
);

our @unit_failing_tests = qw(
    network-devices/wired.t
);

our @config_store_test = qw(
    ConfigStore/Base.t ConfigStore/Group.t
);

=head2 use_test_db

Will override pf::config's globals regarding what database to connect to

=cut

sub use_test_db {

    # override database connection settings
    $Config{'database'}{'host'} = '127.0.0.1';
    $Config{'database'}{'user'} = 'pf-test';
    $Config{'database'}{'pass'} = 'p@ck3tf3nc3';
    $Config{'database'}{'db'} = 'pf-test';
}

=head2 get_all_perl_binaries

Return all the files ending with .pl under

  /usr/local/pf/addons
  /usr/local/pf/lib/pf

and return all the normal files under

  /usr/local/pf/bin
  /usr/local/pf/sbin


=cut

my @excluded_binaries = qw(
   /usr/local/pf/bin/pfcmd
   /usr/local/pf/bin/pfhttpd
   /usr/local/pf/sbin/pfdns
   /usr/local/pf/bin/ntlm_auth_wrapper
   /usr/local/pf/bin/mysql_fingerbank_import.sh
   /usr/local/pf/addons/sourcefire/pfdetect.pl
);
my %exclusions = map { $_ => 1 } @excluded_binaries;

sub get_all_perl_binaries {

    my @list;

    # find2perl /usr/local/pf/lib/pf /usr/local/pf/addons -name "*.pl"
    # Except that I'm explicitly throwing out addons/legacy/...
    File::Find::find({
        wanted => sub {
            /^.*\.pl\z/s
            && $File::Find::name !~ /^.*addons\/legacy\/.*\.pl\z/s
            && push(@list, $File::Find::name) if not exists $exclusions{ $File::Find::name } ;
        }}, '/usr/local/pf/lib/pf', '/usr/local/pf/addons'
    );

    # find2perl /usr/local/pf/bin /usr/local/pf/sbin -type f
    File::Find::find({
        wanted => sub {
            # add to list if it's a regular file
            push(@list, $File::Find::name) if ((-f $File::Find::name) &&
                not exists $exclusions{ $File::Find::name } );
        }}, '/usr/local/pf/bin', '/usr/local/pf/sbin'
    );


    return @list;
}

=head2 get_all_perl_cgi

Return all the files ending with .cgi under

  /usr/local/pf/html

=cut

sub get_all_perl_cgi {

    my @list;

    # find2perl /usr/local/pf/html -name "*.cgi"
    File::Find::find({
        wanted => sub {
            /^.*\.cgi\z/s && push(@list, $File::Find::name);
        }}, '/usr/local/pf/html'
    );

    return @list;
}

=head2 get_all_perl_modules

Return all the files ending with .pm under

  /usr/local/pf/addons
  /usr/local/pf/conf/authentication

=cut

sub get_all_perl_modules {

    my @list;

    # find2perl /usr/local/pf/lib/pf /usr/local/pf/addons -name "*.pm"
    # Except that I'm explictly throwing out anything in addons/legacy/
    File::Find::find({
        wanted => sub {
            /^.*\.pm\z/s
            && $File::Find::name !~ /^.*addons\/legacy\/.*\.pm\z/s
            && push(@list, $File::Find::name);
        }}, '/usr/local/pf/lib/pf', '/usr/local/pf/addons', '/usr/local/pf/html/pfappserver/lib'
    );

    return @list;
}

=head2 get_networkdevices_modules

Return all the files ending with .pm under /usr/local/pf/lib/pf/Switch

=cut

sub get_networkdevices_modules {

    my @list;
    push (@list, '/usr/local/pf/lib/pf/Switch.pm');

    # find2perl /usr/local/pf/lib/pf/Switch -name "*.pm"
    File::Find::find({
        wanted => sub {
            /^.*\.pm\z/s && push(@list, $File::Find::name);
        }}, '/usr/local/pf/lib/pf/Switch'
    );

    return @list;
}

=head2 get_all_unittests

Return all the files /usr/loca/pf/t/unitest

=cut

sub get_all_unittests {

    my @list;

    # find2perl /usr/local/pf/lib/pf/Switch -name "*.pm"
    File::Find::find({
        wanted => sub {
            if ($File::Find::name =~ m#^\Q$Bin\E/unittest/(.*\.t)$# ) {
                push(@list, "unittest/$1");
            }
        }}, "$Bin/unittest"
    );
    return @list;
}

=head2 get_networkdevices_classes

Return the pf::Switch::Device form for all modules under /usr/local/pf/lib/pf/Switch except constants.pm and Generic.pm

=cut

sub get_networkdevices_classes {

    my @modules = get_networkdevices_modules();
    my @classes;
    foreach my $module (@modules) {
        # skip constants.pm and Generic.pm
        next if ($module =~ /constants\.pm$/ || $module =~ /Generic\.pm$/);
        # get rid of path
        $module =~ s|^/usr/local/pf/lib/||;
        # get rid of ending .pm
        $module =~ s|\.pm$||;
        # change slashes for ::
        $module =~ s|/|::|g;
        push(@classes, $module);
    }
    return @classes;
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2017 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;
