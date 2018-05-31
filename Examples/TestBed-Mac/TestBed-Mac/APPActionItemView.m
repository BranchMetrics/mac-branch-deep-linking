//
//  APPActionItemView.m
//  TestBed-Mac
//
//  Created by Edward on 5/30/18.
//  Copyright © 2018 Branch. All rights reserved.
//

#import "APPActionItemView.h"

@interface APPActionItemSubview : NSView
@property (assign) BOOL selected;
@end

@implementation APPActionItemSubview

- (void)drawRect:(NSRect)dirtyRect {
    if (self.selected) {
        [[NSColor selectedTextBackgroundColor] set];
        NSRectFill([self bounds]);
    }
    [super drawRect:dirtyRect];
}

@end

#pragma mark - APPActionItemView

@implementation APPActionItemView

- (void)setHighlightState:(NSCollectionViewItemHighlightState)highlightState_ {
    [super setHighlightState:highlightState_];
    BOOL selected_ =
        (highlightState_ == NSCollectionViewItemHighlightAsDropTarget ||
        highlightState_ == NSCollectionViewItemHighlightForSelection);
    [(APPActionItemSubview*)[self view] setSelected:selected_];
    [(APPActionItemSubview*)[self view] setNeedsDisplay:YES];
}

- (NSCollectionViewItemHighlightState) highlightState {
    return [super highlightState];
}

@end
