//
//  MADExplorerViewDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADExplorerViewDelegate_h
#define Reports_MADExplorerViewDelegate_h

#import <UIKit/UICollectionViewFlowLayout.h>

@protocol MADExplorerProtocol, UIGestureRecognizerDelegate;

@interface MADExplorerViewDelegate : NSObject
    <UICollectionViewDelegateFlowLayout>

    - (instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections;
    
    @property (nonatomic, weak) id <MADExplorerProtocol,
                                        UIGestureRecognizerDelegate> delegate;

    @property (nonatomic, readwrite, assign, getter=isEditing) BOOL editing;
    @property (nonatomic, readwrite, assign, getter=isShowingPopover) BOOL showingPopover;

    @property (readonly) NSUInteger numberOfItemsSelected;
    @property (readonly) NSUInteger numberOfItemsHighlighted;

    - (NSArray <NSIndexPath *> *)indexPathsForSelectedItems;
    - (NSArray <NSIndexPath *> *)indexPathsForHighlightedItems;

    - (void)collectionView:(UICollectionView *)collectionView allowSelection:(BOOL)allowSelection;

@end

#endif
