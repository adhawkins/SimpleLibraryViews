configure_file(install.xml.in install.xml)

install(FILES install.xml Plugin.pm Settings.pm strings.txt
	DESTINATION SimpleLibraryViews)

install(DIRECTORY HTML DESTINATION SimpleLibraryViews)