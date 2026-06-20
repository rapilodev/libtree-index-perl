
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Tree::Indexed::XS',
    VERSION_FROM  => 'lib/Tree/Indexed/XS.pm',
    # Ensure BOTH C files are included here!
    OBJECT        => 'XS$(OBJ_EXT) node_store$(OBJ_EXT)',
    INC           => '-I.', 
);