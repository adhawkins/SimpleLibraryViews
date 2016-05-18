# Simple Library Views plugin for Logitech Media Server
# Copyright (C) 2016 Andy Hawkins
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Andy Hawkins - andy@gently.org.uk

package Plugins::SimpleLibraryViews::Plugin;

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
	$log->info("Scheduling library register, new: '" . $prefs->get('libraries') . "'");

	my @newLibraries = split(/;/, $prefs->get('libraries'));

	foreach my $library (@newLibraries) {
		$library =~ s/^\s+|\s+$//g;
	}

	my %newLibrariesHash = map { $_ => 1 } @newLibraries;

	my $libs = Slim::Music::VirtualLibraries->getLibraries();

	foreach my $libid (keys % {$libs})
	{
		my $name = Slim::Music::VirtualLibraries->getNameForId($libid);

		$log->info("Found registered lib ID ". $libid . ", name '" . $name);

		$name =~ /^SimpleLibraryViews (.*)/ || next;

		my $slvLib = $1;
		$log->info("Found SLV lib: '" . $slvLib . "'");

		if (! exists($newLibrariesHash{$slvLib}))
		{
			$log->info("Unregisering lib '" . $name . "'");
			Slim::Music::VirtualLibraries->unregisterLibrary($libid);
		}
	}

	registerLibraries();

	Slim::Control::Request::executeRequest( undef, [ 'rescan' ] );
}

sub registerLibraries {
	$log->info("In registerLibraries: '" . $prefs->get('libraries') . "'");

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
			my $newLibFile = $dir . "/.simple-library-views-" . $libName;

			if (-f $libFile || -f $newLibFile) {
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
