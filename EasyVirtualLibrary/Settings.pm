package Plugins::EasyVirtualLibrary::Settings;

use strict;
use warnings;

use base qw(Slim::Web::Settings);

use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $log = logger('plugin.easyvirtuallibrary');
my $prefs = preferences('plugin.easyvirtuallibrary');

sub new {
	my $class = shift;

	$class->SUPER::new;
}

sub name {
	return Slim::Web::HTTP::CSRF->protectName('PLUGIN_EASY_VIRTUAL_LIBRARY');
}

sub page {
	return Slim::Web::HTTP::CSRF->protectURI('plugins/EasyVirtualLibrary/settings/basic.html');
}

sub prefs {
	return ($prefs, 'libraries');
}

sub handler {
	my ($class, $client, $params, $callback, @args) = @_;

	if ( $params->{'saveSettings'} ) {
		$log->debug('Saving plugin preferences');

		my $force_register = 0;
		$log->debug("Comparing " . $prefs->get('libraries') . " with " . $params->{'pref_libraries'} );
		if ( $prefs->get('libraries') ne $params->{'pref_libraries'} ) {
			$log->debug("Preference 'libraries' changed");
			$prefs->set( 'libraries', $params->{'pref_libraries'} );
			$force_register = 1;
		}

		if ($force_register) {
			$log->info("Forcing re-registering of libraries due to settings changes");
			Plugins::EasyVirtualLibrary::Plugin::scheduleRegisterLibraries();
		}
	}

	return $class->SUPER::handler($client, $params);
}

1;

__END__
