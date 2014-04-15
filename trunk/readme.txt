USB CopyNES Blue

This code is a fork of USB CopyNES from retrousb.com. Original source, and USB CopyNES device are available at: http://www.retrousb.com/product_info.php?products_id=36

Compilation requires Visual Studio 2008.

src/     - source files for program
src/tmp/ - intermediate files created during compilation
bin/     - output executable, and data files used for program

Notes:

MAPPERS.DAT format
  The first line is 6 integers:
    = (number of categories + 7) * 4
    = column of plugin name
    = column of plugin filename
    = mapper number
    = column of plugin description
    = column of end of line
  The second line is a list of integers indicating which line of the file
    each category begins at.
    Note that line #0 begins on the third line of the file, since two lines
    of other information appear before the plugin list.
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
