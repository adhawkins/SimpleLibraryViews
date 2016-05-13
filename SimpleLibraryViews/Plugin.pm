package Plugins::SimpleLibraryViews::Plugin;

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
use Slim::Control::Request;

my $log = Slim::Utils::Log->addLogCategory({
        'category'     => 'plugin.simplelibraryviews',
        'defaultLevel' => 'WARN',
        'description'  => 'PLUGIN_SIMPLE_LIBRARY_VIEWS_DESC',
});

if ( main::WEBUI ) {
	require Plugins::SimpleLibraryViews::Settings;
}

my $prefs = preferences('plugin.simplelibraryviews');

my @libraryIDs=();

sub initPlugin {
	my $class = shift;

	$log->info("In initPlugin for SimpleLibraryViews");

	if ( main::WEBUI ) {
		Plugins::SimpleLibraryViews::Settings->new;
	}

	registerLibraries();

	$class->SUPER::initPlugin(@_);
}

sub scheduleRegisterLibraries {
	$log->info("Scheduling library register");

	Slim::Control::Request::executeRequest( undef, [ 'rescan' ] );
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
				name => "SimpleLibraryViews $library",
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
	return 'PLUGIN_SIMPLE_LIBRARY_VIEWS';
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

			my $libFile = $dir . "/simple-library-views-" . $libName;
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
