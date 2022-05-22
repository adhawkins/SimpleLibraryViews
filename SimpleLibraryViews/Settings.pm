# Simple Library Views plugin for Logitech Media Server
# Copyright (C) 2016-2022 Andy Hawkins
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

package Plugins::SimpleLibraryViews::Settings;

use strict;
use warnings;

use base qw(Slim::Web::Settings);

use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $log = logger('plugin.simplelibraryviews');
my $prefs = preferences('plugin.simplelibraryviews');

sub new {
	my $class = shift;

	$class->SUPER::new;
}

sub name {
	return Slim::Web::HTTP::CSRF->protectName('PLUGIN_SIMPLE_LIBRARY_VIEWS');
}

sub page {
	return Slim::Web::HTTP::CSRF->protectURI('plugins/SimpleLibraryViews/settings/basic.html');
}

sub prefs {
	return ($prefs, 'libraries');
}

sub handler {
	my ($class, $client, $params, $callback, @args) = @_;

	if ( $params->{'saveSettings'} ) {
		$log->debug('Saving plugin preferences');

		$log->debug("Comparing " . $prefs->get('libraries') . " with " . $params->{'pref_libraries'} );
		if ( $prefs->get('libraries') ne $params->{'pref_libraries'} ) {
			$prefs->set( 'libraries', $params->{'pref_libraries'} );
			$log->info("Forcing re-registering of libraries due to settings changes");
			Plugins::SimpleLibraryViews::Plugin::scheduleRegisterLibraries();
		}
	}

	return $class->SUPER::handler($client, $params);
}

1;

__END__
