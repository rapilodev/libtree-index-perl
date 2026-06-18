
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Tree::Indexed::XS',
    PREREQ_PM     => {},
    OBJECT        => '$(O_FILES)', # Compiles both .c and .xs files
    AUTHOR        => 'You',
);