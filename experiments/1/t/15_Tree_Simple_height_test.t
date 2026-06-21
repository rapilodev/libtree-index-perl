#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 67;

BEGIN { 
	use_ok('Tree::Simple:XS'); 
};


{ # test height (with pictures)
    
    my $tree = Tree::Simple:XS->new();
    isa_ok($tree, 'Tree::Simple:XS');
    
    my $D = Tree::Simple:XS->new('D');
    isa_ok($D, 'Tree::Simple:XS');
    
    $tree->addChild($D);
    
    #   |
    #  <D>
    
    cmp_ok($D->getHeight(), '==', 1, '... D has a height of 1');
    
    my $E = Tree::Simple:XS->new('E');
    isa_ok($E, 'Tree::Simple:XS');
    
    $D->addChild($E);
    
    #   |
    #  <D>
    #    \
    #    <E>
    
    cmp_ok($D->getHeight(), '==', 2, '... D has a height of 2');
    cmp_ok($E->getHeight(), '==', 1, '... E has a height of 1');
    
    my $F = Tree::Simple:XS->new('F');
    isa_ok($F, 'Tree::Simple:XS');
    
    $E->addChild($F);
    
    #   |
    #  <D>
    #    \
    #    <E>
    #      \
    #      <F>
    
    cmp_ok($D->getHeight(), '==', 3, '... D has a height of 3');
    cmp_ok($E->getHeight(), '==', 2, '... E has a height of 2');
    cmp_ok($F->getHeight(), '==', 1, '... F has a height of 1');
    
    my $C = Tree::Simple:XS->new('C');
    isa_ok($C, 'Tree::Simple:XS');
    
    $D->addChild($C);
    
    #    |
    #   <D>
    #   / \
    # <C> <E>
    #       \
    #       <F>
    
    cmp_ok($D->getHeight(), '==', 3, '... D has a height of 3');
    cmp_ok($E->getHeight(), '==', 2, '... E has a height of 2');
    cmp_ok($F->getHeight(), '==', 1, '... F has a height of 1');
    cmp_ok($C->getHeight(), '==', 1, '... C has a height of 1');
    
    my $B = Tree::Simple:XS->new('B');
    isa_ok($B, 'Tree::Simple:XS');
    
    $C->addChild($B);
    
    #      |
    #     <D>
    #     / \
    #   <C> <E>
    #   /     \
    # <B>     <F>
    
    
    cmp_ok($D->getHeight(), '==', 3, '... D has a height of 3');
    cmp_ok($E->getHeight(), '==', 2, '... E has a height of 2');
    cmp_ok($F->getHeight(), '==', 1, '... F has a height of 1');
    cmp_ok($C->getHeight(), '==', 2, '... C has a height of 2');
    cmp_ok($B->getHeight(), '==', 1, '... B has a height of 1');
    
    my $A = Tree::Simple:XS->new('A');
    isa_ok($A, 'Tree::Simple:XS');
    
    $B->addChild($A);
    
    #        |
    #       <D>
    #       / \
    #     <C> <E>
    #     /     \
    #   <B>     <F>
    #   /         
    # <A>         
    
    cmp_ok($D->getHeight(), '==', 4, '... D has a height of 4');
    cmp_ok($E->getHeight(), '==', 2, '... E has a height of 2');
    cmp_ok($F->getHeight(), '==', 1, '... F has a height of 1');
    cmp_ok($C->getHeight(), '==', 3, '... C has a height of 3');
    cmp_ok($B->getHeight(), '==', 2, '... B has a height of 2');
    cmp_ok($A->getHeight(), '==', 1, '... A has a height of 1');
    
    my $G = Tree::Simple:XS->new('G');
    isa_ok($G, 'Tree::Simple:XS');
    
    $E->insertChild(0, $G);
    
    #        |
    #       <D>
    #       / \
    #     <C> <E>
    #     /   / \
    #   <B> <G> <F>
    #   /         
    # <A>         
    
    cmp_ok($D->getHeight(), '==', 4, '... D has a height of 4');
    cmp_ok($E->getHeight(), '==', 2, '... E has a height of 2');
    cmp_ok($F->getHeight(), '==', 1, '... F has a height of 1');
    cmp_ok($G->getHeight(), '==', 1, '... G has a height of 1');
    cmp_ok($C->getHeight(), '==', 3, '... C has a height of 3');
    cmp_ok($B->getHeight(), '==', 2, '... B has a height of 2');
    cmp_ok($A->getHeight(), '==', 1, '... A has a height of 1');
    
    my $H = Tree::Simple:XS->new('H');
    isa_ok($H, 'Tree::Simple:XS');
    
    $G->addChild($H);
    
    #        |
    #       <D>
    #       / \
    #     <C> <E>
    #     /   / \
    #   <B> <G> <F>
    #   /     \    
    # <A>     <H>    
    
    cmp_ok($D->getHeight(), '==', 4, '... D has a height of 4');
    cmp_ok($E->getHeight(), '==', 3, '... E has a height of 3');
    cmp_ok($F->getHeight(), '==', 1, '... F has a height of 1');
    cmp_ok($G->getHeight(), '==', 2, '... G has a height of 2');
    cmp_ok($H->getHeight(), '==', 1, '... H has a height of 1');
    cmp_ok($C->getHeight(), '==', 3, '... C has a height of 3');
    cmp_ok($B->getHeight(), '==', 2, '... B has a height of 2');
    cmp_ok($A->getHeight(), '==', 1, '... A has a height of 1');

    ok($B->removeChild($A), '... removed A subtree from B tree');

    #        |
    #       <D>
    #       / \
    #     <C> <E>
    #     /   / \
    #   <B> <G> <F>
    #         \    
    #         <H> 

    cmp_ok($D->getHeight(), '==', 4, '... D has a height of 4');
    cmp_ok($E->getHeight(), '==', 3, '... E has a height of 3');
    cmp_ok($F->getHeight(), '==', 1, '... F has a height of 1');
    cmp_ok($G->getHeight(), '==', 2, '... G has a height of 2');
    cmp_ok($H->getHeight(), '==', 1, '... H has a height of 1');
    cmp_ok($C->getHeight(), '==', 2, '... C has a height of 2');
    cmp_ok($B->getHeight(), '==', 1, '... B has a height of 1');
    
    # and the removed tree is ok
    cmp_ok($A->getHeight(), '==', 1, '... A has a height of 1');
    
    ok($D->removeChild($E), '... removed E subtree from D tree');

    #        |
    #       <D>
    #       / 
    #     <C> 
    #     /     
    #   <B>

    cmp_ok($D->getHeight(), '==', 3, '... D has a height of 3');
    cmp_ok($C->getHeight(), '==', 2, '... C has a height of 2');
    cmp_ok($B->getHeight(), '==', 1, '... B has a height of 1');
    
    # and the removed trees are ok
    cmp_ok($E->getHeight(), '==', 3, '... E has a height of 3');
    cmp_ok($F->getHeight(), '==', 1, '... F has a height of 1');
    cmp_ok($G->getHeight(), '==', 2, '... G has a height of 2');
    cmp_ok($H->getHeight(), '==', 1, '... H has a height of 1');    
    
    ok($D->removeChild($C), '... removed C subtree from D tree');

    #        |
    #       <D>

    cmp_ok($D->getHeight(), '==', 1, '... D has a height of 1');
    
    # and the removed tree is ok
    cmp_ok($C->getHeight(), '==', 2, '... C has a height of 2');
    cmp_ok($B->getHeight(), '==', 1, '... B has a height of 1');      
}
