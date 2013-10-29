scripts
=======

Place to stash useful scripts


drive.rb
========

A small multithreaded ruby ( >= 2.0.0) script to prepare and populate drives.

wifi.sh
========

A small ruby script ( >= 1.9.3) to enable or disable WiFi based on a bunch of conditions. (With Shebang)

Rough non-exact translation of current ruby logic:
- If after 5, look for home WiFi network, if found leave WiFi on.
- If before 5, look for work wired network, if not found turn on WiFi.