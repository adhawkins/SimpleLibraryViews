package Plugins::EasyVirtualLibrary::Plugin;

# Logitech Media Server Copyright 2001-2014 Logitech.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

use strict;

use base qw(Slim::Plugin::Base);

use Slim::Menu::BrowseLibrary;
use Slim::Utils::Log;
use Slim::Utils::Misc;
use File::Basename;
use Slim::Utils::Prefs;
use Slim::Utils::Timers;
use Time::HiRes;

use constant REGISTER_LIBRARIES_DELAY => 5;

my $log = Slim::Utils::Log->addLogCategory({
        'category'     => 'plugin.easyvirtuallibrary',
        'defaultLevel' => 'WARN',
        'description'  => 'PLUGIN_EASY_VIRTUAL_LIBRARY_DESC',
});

if ( main::WEBUI ) {
	require Plugins::EasyVirtualLibrary::Settings;
}

my $prefs = preferences('plugin.easyvirtuallibrary');

my @libraryIDs=();

sub initPlugin {
	my $class = shift;

	$log->info("In initPlugin for EasyVirtualLibrary");

	if ( main::WEBUI ) {
		Plugins::EasyVirtualLibrary::Settings->new;
	}

	scheduleRegisterLibraries();

	$class->SUPER::initPlugin(@_);
}

sub scheduleRegisterLibraries {
	$log->info("Scheduling library register");

	Slim::Utils::Timers::killOneTimer( 1, \&registerLibraries );

	Slim::Utils::Timers::setTimer( 1,
		Time::HiRes::time() + REGISTER_LIBRARIES_DELAY,
		\&registerLibraries );
}

sub registerLibraries {
	$log->info("In registerLibraries: '" . $prefs->get('libraries') . "'");

	foreach my $libraryID (@libraryIDs) {
		$log->info("Unregistering $libraryID");

		Slim::Music::VirtualLibraries->unregisterLibrary($libraryID);
	}

	@libraryIDs=();

	my @libraries = split(/;/, $prefs->get('libraries'));
	foreach my $library (@libraries) {
		$library =~ s/^\s+|\s+$//g;
		$log->info("Checking library '$library'");
		if ($library ne "" ) {
			$log->info("Processing library '$library'");

			my $newID = Slim::Music::VirtualLibraries->registerLibrary( {
				id => $library,
				name => "EasyVirtualLibrary $library",
				scannerCB => sub {
					my $libraryId = shift;
					createLibrary($libraryId, $library);
				}
			} );

			$log->info("Registered library $newID");
			push @libraryIDs, $newID;
		}
	}
}

sub getDisplayName {
	return 'PLUGIN_EASY_VIRTUAL_LIBRARY';
}

sub createLibrary {
	my $id = shift;
	my $libName = shift;

	$log->info("Building library id " . $id . " for name " . $libName);

	my $rs = Slim::Schema->resultset('Track')->search;
	my $obj;

	do {
		$obj = $rs->next;
		if ($obj) {
			my $trackid = $obj->get_column("id");
			my $url = $obj->get_column("url");
			my $dir = dirname(Slim::Utils::Misc::pathFromFileURL($url));

			$log->debug("ID: " . $trackid . ", URL: " . $url .	", path: " . $dir);

			my $libFile = $dir . "/easy-virtual-library-" . $libName;
			if (-f $libFile) {
				$log->debug("Adding " . $url . " to library " . $libName);

				my $dbh = Slim::Schema->dbh;
				$dbh->do(
					sprintf(
							q{INSERT OR IGNORE INTO library_track (library, track) values ('%s','%s')},
							$id, $trackid
						)
					);
			}
		}
	} while ($obj);
}

1;

__END__
