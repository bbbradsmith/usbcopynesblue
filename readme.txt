USB CopyNES Blue

This code is a fork of USB CopyNES from retrousb.com. Original source, and USB CopyNES device are available at: http://www.retrousb.com/product_info.php?products_id=36

Compilation target is Visual Studio 2017.
Older VS 2008 and 2010 solutions are present but unmaintained.

src/     - source files for program
src/tmp/ - intermediate files created during compilation
bin/     - output executable, and data files used for program

Automated preview build:
https://ci.appveyor.com/project/bbbradsmith/usbcopynesblue/build/artifacts

Notes:

MAPPERS.DAT format
  The first line is 5 integers:
    = column of plugin name
    = column of plugin filename
    = mapper number
    = column of plugin description
    = column of end of line
  Each category header should have: (aligned to the specified columns)
    * instead of plugin name
    empty filename (spaces)
    0 as mapper number
    title of category instead of plugin description
  Each plugin entry in a category should have: (aligned to the specified columns)
    plugin name
    filename
    mapper number
    description
  If a line begins with ****, the rest of the line is completely ignored.
