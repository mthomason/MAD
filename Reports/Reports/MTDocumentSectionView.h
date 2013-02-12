//
//  MTDocumentSectionView.h
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MTDocumentSectionViewDelegate
@optional
- (void)didUpdateLayout:(id)sender;
@end

@interface MTDocumentSectionView : UICollectionView
    <UIGestureRecognizerDelegate>

@property (assign, nonatomic) id <MTDocumentSectionViewDelegate> sectionDelegate;

@end