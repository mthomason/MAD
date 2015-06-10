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

@protocol MTDocumentSectionViewDelegate;

typedef NS_ENUM(NSUInteger, MADBorderState) {
    MADBorderStateNormal,
    MADBorderStateSelected,
    MADBorderStateDisabled
};

@interface MADDesignerSectionView : UICollectionView
    <UIGestureRecognizerDelegate>

@property (nonatomic, assign) id <MTDocumentSectionViewDelegate> sectionDelegate;

@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) BOOL selected;

- (void)removeItemAtIndex:(NSIndexPath *)deletePath update:(void (^)())update animationComplete:(void (^)(BOOL finished))animationComplete completion:(void (^)(BOOL finished))completion;

- (void)insertItemAtIndex:(NSIndexPath *)path update:(void (^)())update animationComplete:(void (^)(BOOL finished))animationComplete completion:(void (^)(BOOL finished))completion;

@end

@protocol MTDocumentSectionViewDelegate
@optional
- (void)didUpdateLayout:(MADDesignerSectionView *)sectionView;
@end

#endif
