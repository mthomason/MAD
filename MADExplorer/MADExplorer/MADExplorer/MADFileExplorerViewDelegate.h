//
//  MADFileExplorerViewDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileExplorerViewDelegate_h
#define Reports_MADFileExplorerViewDelegate_h

#import <UIKit/UICollectionViewFlowLayout.h>

@protocol MADExplorerProtocol, UIGestureRecognizerDelegate;

@interface MADFileExplorerViewDelegate : NSObject
    <UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout>

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
