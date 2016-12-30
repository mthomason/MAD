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

@protocol MADFileExplorerViewDelegateProtocol;
@protocol UIGestureRecognizerDelegate;

typedef id <MADFileExplorerViewDelegateProtocol, UIGestureRecognizerDelegate> MADFileExplorerDelegate;

@interface MADFileExplorerViewDelegate : NSObject
    <UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout>

    - (instancetype)initWithNumberOfSections:(NSUInteger)numberOfSections;
    
    @property (nonatomic, weak) MADFileExplorerDelegate delegate;

    @property (nonatomic, readonly, strong) NSMutableArray <NSMutableIndexSet *> *selected;
    @property (nonatomic, readonly, strong) NSMutableArray <NSMutableIndexSet *> *highlighted;
    @property (nonatomic, readwrite, assign, getter=isEditing) BOOL editing;

    @property (readonly) NSUInteger numberOfItemsSelected;
    @property (readonly) NSUInteger numberOfItemsHighlighted;

@end

#endif
