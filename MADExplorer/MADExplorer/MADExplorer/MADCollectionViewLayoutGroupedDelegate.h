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

@interface MADFileExplorerViewDelegate : NSObject
    <UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout>

    - (id)initWithNumberOfSections:(NSUInteger)numberOfSections;
    
    @property (nonatomic, weak) NSObject <MADFileExplorerViewDelegateProtocol> *delegate;
    @property (nonatomic, readonly, strong) NSMutableArray <NSMutableIndexSet *> *selected;
    @property (nonatomic, readonly, strong) NSMutableArray <NSMutableIndexSet *> *highlighted;
    @property (nonatomic, readwrite, assign, getter=isEditing) BOOL edit;

    @property (readonly) NSUInteger numberOfItemsSelected;
    @property (readonly) NSUInteger numberOfItemsHighlighted;

@end

#endif
