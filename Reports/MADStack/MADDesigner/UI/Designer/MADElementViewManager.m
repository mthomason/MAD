//
//  MADElementViewManager.m
//  MAD Designer
//
//  Created by Michael on 5/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "MADElementViewManager.h"
#import "MADDesignerElementView.h"
#import <UIKit/UITapGestureRecognizer.h>

@interface MADElementViewManager ()

    @property (nonatomic, strong) NSMutableDictionary <NSNumber *, MADDesignerElementView *> *elementViewsDictionary;
    @property (nonatomic, strong) NSMutableSet <MADDesignerElementView *> *visibleElementViews;
    @property (nonatomic, strong) NSMutableSet <NSNumber *> *selectedElementIDs;

@end

@implementation MADElementViewManager

- (UIView *)viewForObjectID:(NSNumber *)objectID {
    return [self.elementViewsDictionary objectForKey:objectID];
}

#pragma mark -
#pragma mark Lazy Load

- (NSMutableSet <NSNumber *> *)selectedElementIDs {
    if (!_selectedElementIDs) {
        NSMutableSet <NSNumber *> *selectedElementIDs;
        selectedElementIDs = [[NSMutableSet alloc] init];
        _selectedElementIDs = selectedElementIDs;
    }
    return _selectedElementIDs;
}

- (NSMutableSet <MADDesignerElementView *> *)visibleElementViews {
    if (!_visibleElementViews) {
        NSMutableSet <MADDesignerElementView *> *visibleElementViews;
        visibleElementViews = [[NSMutableSet alloc] init];
        _visibleElementViews = visibleElementViews;
    }
    return _visibleElementViews;
}

- (NSMutableDictionary <NSNumber *, MADDesignerElementView *> *)elementViewsDictionary {
    if (!_elementViewsDictionary) {
        NSMutableDictionary <NSNumber *, MADDesignerElementView *> *elementViewsDictionary;
        elementViewsDictionary = [[NSMutableDictionary alloc] init];
        _elementViewsDictionary = elementViewsDictionary;
    }
    return _elementViewsDictionary;
}

#pragma mark -
#pragma mark Event handlers

- (void)handleToggleElementView:(UITapGestureRecognizer *)sender {
    
}

@end
