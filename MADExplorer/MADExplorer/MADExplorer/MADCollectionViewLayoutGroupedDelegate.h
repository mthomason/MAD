//
//  MADCollectionViewLayoutGroupedDelegate.h
//  MAD Designer
//
//  Created by Michael Thomason on 5/30/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MADCollectionViewLayoutGroupedDelegate_h
#define Reports_MADCollectionViewLayoutGroupedDelegate_h

#import <Foundation/NSObject.h>
#import <UIKit/UICollectionView.h>
#import <UIKit/UICollectionViewFlowLayout.h>

@protocol MADCollectionViewLayoutFilesDelegate;

@interface MADCollectionViewLayoutGroupedDelegate : NSObject
    <UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout>

    @property (nonatomic, weak) id <MADCollectionViewLayoutFilesDelegate> delegate;

@end

#endif
