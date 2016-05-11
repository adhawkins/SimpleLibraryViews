Slimserver plugin for easy virtual libraries
============================================

This plugin provides an easy mechanism for defining library views for the
Logitech Media Server.

Requirements
------------

This plugin requires Logitech Media Server v7.9.0 or greater.

Installation
------------

Add the following repository to your Logitech Media Server:

http://software.gently.org.uk/slim-plugins/repo.xml

The 'Easy Virtual Libraries' plugin should now be available for installation.

Configuration
-------------

There is a single configuration parameter for the plugin, available through the
web interface in the normal manner.

'Library names' is a semi-colon separated list of library views to define.

Changing this list triggers all library views to be rebuilt.

Adding media to a library view
------------------------------

In order to add an album to a library view, simply create a file named:

'easy-virtual-library-<libraryname>' 

to the directory containing the album's media.

e.g. to add an album to the library 'audiobooks', create a file called 

'easy-virtual-library-auiobooks' 

in the album's directory.

The next time a scan is triggered, the library view will be updated to include the new album.

