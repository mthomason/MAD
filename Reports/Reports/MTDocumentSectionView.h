//
//  MTDocumentSectionView.h
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDocumentSectionView_h
#define Reports_MTDocumentSectionView_h

#import <UIKit/UIKit.h>

@protocol MTDocumentSectionViewDelegate
@optional
- (void)didUpdateLayout:(id)sender;
@end

@interface MTDocumentSectionView : UICollectionView
    <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id <MTDocumentSectionViewDelegate> sectionDelegate;

@end

#endif
