#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 77;

BEGIN { 
	use_ok('Tree::Fast'); 
};


{ # test height (with pictures)
    
    my $tree = Tree::Fast->new();
    isa_ok($tree, 'Tree::Fast');
    
    my $D = Tree::Fast->new('D');
    isa_ok($D, 'Tree::Fast');
    
    $tree->addChild($D);
    
    #   |
    #  <D>
    
    cmp_ok($D->getWidth(), '==', 1, '... D has a width of 1');
    
    my $E = Tree::Fast->new('E');
    isa_ok($E, 'Tree::Fast');
    
    $D->addChild($E);
    
    #   |
    #  <D>
    #    \
    #    <E>
    
    cmp_ok($D->getWidth(), '==', 1, '... D has a width of 1');
    cmp_ok($E->getWidth(), '==', 1, '... E has a width of 1');
    
    my $F = Tree::Fast->new('F');
    isa_ok($F, 'Tree::Fast');
    
    $E->addChild($F);
    
    #   |
    #  <D>
    #    \
    #    <E>
    #      \
    #      <F>
    
    cmp_ok($D->getWidth(), '==', 1, '... D has a width of 1');
    cmp_ok($E->getWidth(), '==', 1, '... E has a width of 1');
    cmp_ok($F->getWidth(), '==', 1, '... F has a width of 1');
    
    my $C = Tree::Fast->new('C');
    isa_ok($C, 'Tree::Fast');
    
    $D->addChild($C);
    
    #    |
    #   <D>
    #   / \
    # <C> <E>
    #       \
    #       <F>
    
    cmp_ok($D->getWidth(), '==', 2, '... D has a width of 2');
    cmp_ok($E->getWidth(), '==', 1, '... E has a width of 1');
    cmp_ok($F->getWidth(), '==', 1, '... F has a width of 1');
    cmp_ok($C->getWidth(), '==', 1, '... C has a width of 1');
    
    my $B = Tree::Fast->new('B');
    isa_ok($B, 'Tree::Fast');
    
    $D->addChild($B);
    
    #        |
    #       <D>
    #      / | \
    #   <B> <C> <E>
    #             \
    #             <F>
    
    
    cmp_ok($D->getWidth(), '==', 3, '... D has a width of 3');
    cmp_ok($E->getWidth(), '==', 1, '... E has a width of 1');
    cmp_ok($F->getWidth(), '==', 1, '... F has a width of 1');
    cmp_ok($C->getWidth(), '==', 1, '... C has a width of 1');
    cmp_ok($B->getWidth(), '==', 1, '... B has a width of 1');
        
    
    my $A = Tree::Fast->new('A');
    isa_ok($A, 'Tree::Fast');
    
    $E->addChild($A);
    
    #        |
    #       <D>
    #      / | \
    #   <B> <C> <E>
    #           / \
    #         <A> <F>       
    
    cmp_ok($D->getWidth(), '==', 4, '... D has a width of 4');
    cmp_ok($E->getWidth(), '==', 2, '... E has a width of 2');
    cmp_ok($F->getWidth(), '==', 1, '... F has a width of 1');
    cmp_ok($C->getWidth(), '==', 1, '... C has a width of 1');
    cmp_ok($B->getWidth(), '==', 1, '... B has a width of 1');
    cmp_ok($A->getWidth(), '==', 1, '... A has a width of 1');
    
    my $G = Tree::Fast->new('G');
    isa_ok($G, 'Tree::Fast');
    
    $E->insertChild(1, $G);
    
    #        |
    #       <D>
    #      / | \
    #   <B> <C> <E>
    #          / | \
    #       <A> <G> <F>         
    
    cmp_ok($D->getWidth(), '==', 5, '... D has a width of 5');
    cmp_ok($E->getWidth(), '==', 3, '... E has a width of 3');
    cmp_ok($F->getWidth(), '==', 1, '... F has a width of 1');
    cmp_ok($G->getWidth(), '==', 1, '... G has a width of 1');
    cmp_ok($C->getWidth(), '==', 1, '... C has a width of 1');
    cmp_ok($B->getWidth(), '==', 1, '... B has a width of 1');
    cmp_ok($A->getWidth(), '==', 1, '... A has a width of 1');
    
    my $H = Tree::Fast->new('H');
    isa_ok($H, 'Tree::Fast');
    
    $G->addChild($H);
    
    #        |
    #       <D>
    #      / | \
    #   <B> <C> <E>
    #          / | \
    #       <A> <G> <F> 
    #            |
    #           <H>    
    
    cmp_ok($D->getWidth(), '==', 5, '... D has a width of 5');
    cmp_ok($E->getWidth(), '==', 3, '... E has a width of 3');
    cmp_ok($F->getWidth(), '==', 1, '... F has a width of 1');
    cmp_ok($G->getWidth(), '==', 1, '... G has a width of 1');
    cmp_ok($H->getWidth(), '==', 1, '... H has a width of 1');
    cmp_ok($C->getWidth(), '==', 1, '... C has a width of 1');
    cmp_ok($B->getWidth(), '==', 1, '... B has a width of 1');
    cmp_ok($A->getWidth(), '==', 1, '... A has a width of 1');
    
    my $I = Tree::Fast->new('I');
    isa_ok($I, 'Tree::Fast');
    
    $G->addChild($I);
    
    #        |
    #       <D>
    #      / | \
    #   <B> <C> <E>
    #          / | \
    #       <A> <G> <F> 
    #            | \
    #           <H> <I>   
    
    cmp_ok($D->getWidth(), '==', 6, '... D has a width of 6');
    cmp_ok($E->getWidth(), '==', 4, '... E has a width of 4');
    cmp_ok($F->getWidth(), '==', 1, '... F has a width of 1');
    cmp_ok($G->getWidth(), '==', 2, '... G has a width of 2');
    cmp_ok($H->getWidth(), '==', 1, '... H has a width of 1');
    cmp_ok($I->getWidth(), '==', 1, '... I has a width of 1');    
    cmp_ok($C->getWidth(), '==', 1, '... C has a width of 1');
    cmp_ok($B->getWidth(), '==', 1, '... B has a width of 1');
    cmp_ok($A->getWidth(), '==', 1, '... A has a width of 1');      

    ok($E->removeChild($A), '... removed A subtree from B tree');

    #        |
    #       <D>
    #      / | \
    #   <B> <C> <E>
    #            | \
    #           <G> <F> 
    #            | \
    #           <H> <I>  

    cmp_ok($D->getWidth(), '==', 5, '... D has a width of 5');
    cmp_ok($E->getWidth(), '==', 3, '... E has a width of 3');
    cmp_ok($F->getWidth(), '==', 1, '... F has a width of 1');
    cmp_ok($G->getWidth(), '==', 2, '... G has a width of 2');
    cmp_ok($H->getWidth(), '==', 1, '... H has a width of 1');
    cmp_ok($C->getWidth(), '==', 1, '... C has a width of 2');
    cmp_ok($B->getWidth(), '==', 1, '... B has a width of 1');
    
    # and the removed tree is ok
    cmp_ok($A->getWidth(), '==', 1, '... A has a width of 1');
    
    ok($D->removeChild($E), '... removed E subtree from D tree');

    #        |
    #       <D>
    #      / | 
    #   <B> <C>

    cmp_ok($D->getWidth(), '==', 2, '... D has a width of 2');
    cmp_ok($C->getWidth(), '==', 1, '... C has a width of 1');
    cmp_ok($B->getWidth(), '==', 1, '... B has a width of 1');
    
    # and the removed trees are ok
    cmp_ok($E->getWidth(), '==', 3, '... E has a width of 3');
    cmp_ok($F->getWidth(), '==', 1, '... F has a width of 1');
    cmp_ok($G->getWidth(), '==', 2, '... G has a width of 2');
    cmp_ok($H->getWidth(), '==', 1, '... H has a width of 1');    
    
    ok($D->removeChild($C), '... removed C subtree from D tree');

    #        |
    #       <D>
    #      /  
    #   <B> 

    cmp_ok($D->getWidth(), '==', 1, '... D has a width of 1');
    cmp_ok($B->getWidth(), '==', 1, '... B has a width of 1');
    
    # and the removed tree is ok
    cmp_ok($C->getWidth(), '==', 1, '... C has a width of 1');
      
}
