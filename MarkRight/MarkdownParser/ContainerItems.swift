//
//  ContainerItems.swift
//  SwiftCMD
//
//  Created by Octree on 2018/4/12.
//  Copyright © 2018年 Octree. All rights reserved.
//

import Foundation


/*********************************************
 ********** Container Items Parser ***********
 ********************************************/

/// blockQuoteMarker = ">", [" "];
let blockQuoteMarker = string(">") <* string(" ").optional
//  blockQuote = blockQuteMarker, inlineLine, {blockQuteMarker, inlineLine};   (*2. Laziness is ignored for now*)
let blockQuote = ContainerNode.blockQuote <^> (blockQuoteMarker *> inlineLine).many1

let taskListUncheckMarker = { _ in curry(ContainerNode.taskListItem)(false) } <^> string("- [ ] ")
let taskListCheckedMarker = { _ in curry(ContainerNode.taskListItem)(true) } <^> string("- [x] ")
let taskListMarker = taskListUncheckMarker <|> taskListCheckedMarker


/// bulletListMarker = "-";    (*plus and star ignored for now*)

let bulletListMarker = character { "+-*".contains($0) }.difference(taskListMarker)
func depthBulletListMarker(depth: Int) -> MDParser<Character> {
    
    let indentation = space.repeat(4 * depth - 4)
    return indentation *> bulletListMarker
}

/// orderedListMarker = digit, "."                            | ")";
let digits = character { CharacterSet.decimalDigits.contains($0) }.many1
let orderedListMarker = digits <* string(".")
func depthOrderedListMarker(depth: Int) -> MDParser<[Character]> {
    
    let indentation = listItemIndentation.repeat(depth - 1)
    return indentation *> orderedListMarker
}

func depthTaskListItem(depth: Int) -> MDParser<ContainerNode> {
    let indentation = listItemIndentation.repeat(depth - 1)
    return (indentation *> taskListMarker) <*> listItemParagraph(depth: depth)
}

func depthBulletListItem(depth: Int) -> MDParser<ContainerNode> {
    
    let indentation = listItemIndentation.repeat(depth - 1)
    return indentation *> bulletListMarker *> space *> listItemParagraph(depth: depth)
}

/// orderedListItem = orderedListMarker, 2 * space, listItemLeafBlock;
func depthOrderedListItem(depth: Int) -> MDParser<ContainerNode> {
    
    let indentation = listItemIndentation.repeat(depth - 1)
    return indentation *> orderedListMarker *> space *> listItemParagraph(depth: depth)
}

/// orderedList = orderedListItem, [blankLine], {orderedListItem, [blankLine]};
func depthOrderedList(depth: Int) -> MDParser<ContainerNode> {
    
    return ContainerNode.orderedList <^> (depthOrderedListItem(depth: depth) <* blankLine.optional).many1
}

/// bulletList = bulletListItem, [blankLine], {bulletListItem, [blankLine]};
func depthBulletList(depth: Int) -> MDParser<ContainerNode> {
    
    return ContainerNode.bulletList <^> (depthBulletListItem(depth: depth) <* blankLine.optional).many1
}

func depthTaskList(depth: Int) -> MDParser<ContainerNode> {
    
    return ContainerNode.taskList <^> (depthTaskListItem(depth: depth) <* blankLine.optional).many1
}

//containerBlock = blockQuote;
let containerBlock =  MarkdownNode.container <^> (blockQuote <|> depthOrderedList(depth: 1) <|> depthBulletList(depth: 1) <|> depthTaskList(depth: 1))
