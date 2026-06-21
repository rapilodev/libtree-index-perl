
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Tree::Indexed::XS',
    VERSION_FROM  => 'lib/Tree/Indexed/XS.pm',
    OBJECT        => 'XS$(OBJ_EXT) tree_index$(OBJ_EXT)',
    INC           => '-I.', 
);
