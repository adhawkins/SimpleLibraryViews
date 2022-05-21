---
layout: page
title: Simple Library Views plugin
---

Slimserver plugin for simple library views
=========================================

This plugin provides an easy mechanism for defining library views for the
Logitech Media Server. This software is licensed under the GPL.

Requirements
------------

This plugin requires Logitech Media Server v7.9.0 or greater.

Installation
------------

Add the following repository to your Logitech Media Server:

http://adhawkins.github.io/SimpleLibraryViews/repo.xml

The 'Simple Library Views' plugin should now be available for installation.

Usage
-----

In order to use the Simple Library Views plugin, first you should define the names of the virtual library views you wish to create. This is done by entering the list of library view names into the plugin's settings page, separating each name with a semi-colon.

Once the names of the library views have been defined, albums can be added to a library view by creating a file named:

'simple-library-views-libraryviewname' or '.simple-library-views-libraryviewname' (note that this file name does not have any extension)

in the directory containing the album's media.

e.g. to add an album to the library 'audiobooks', create a file called

'simple-library-views-audiobooks'

or

'.simple-library-views-audiobooks'

in the album's directory.

Library views wiil be updated the next time a scan is triggered, or if changes are made to the list of library view names on the plugin's settings page.


