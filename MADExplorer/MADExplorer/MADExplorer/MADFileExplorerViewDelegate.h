//
//  MADFileExplorerViewDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADFileExplorerViewDelegate_h
#define Reports_MADFileExplorerViewDelegate_h

#import <UIKit/UICollectionViewFlowLayout.h>

@protocol MADFileExplorerViewDelegateProtocol, UIGestureRecognizerDelegate;

@interface MADFileExplorerViewDelegate : NSObject
    <UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout>

    - (instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections;
    
    @property (nonatomic, weak) id <MADFileExplorerViewDelegateProtocol,
                                        UIGestureRecognizerDelegate> delegate;

    @property (nonatomic, readwrite, assign, getter=isEditing) BOOL editing;

    @property (readonly) NSUInteger numberOfItemsSelected;
    @property (readonly) NSUInteger numberOfItemsHighlighted;

    - (NSArray <NSIndexPath *> *)indexPathsForSelectedItems;
    - (NSArray <NSIndexPath *> *)indexPathsForHighlightedItems;

@end

#endif
