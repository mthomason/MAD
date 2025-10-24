//
//  MTDocumentSectionView.h
//  Reports
//
//  Created by Michael Thomason on 2/11/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTDocumentSectionView_h
#define Reports_MTDocumentSectionView_h

#import "MADManagedObjectCollectionView.h"

@protocol MADDesignerSectionLayoutLiquidDelegate;

@class MADDesignerSectionLabel, MADReportSection;

typedef NS_ENUM(NSUInteger, MADBorderState) {
	MADBorderStateNormal,
	MADBorderStateSelected,
	MADBorderStateDisabled
};

@interface MADDesignerSectionView : MADManagedObjectCollectionView

@property (nonatomic, weak) MADDesignerSectionLabel *sectionLabel;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) BOOL selected;

+ (instancetype)newDesignerSectionView:(NSInteger)identifier
				  designViewIdentifier:(NSUInteger)designViewIdentifier
							 isVisible:(BOOL)isVisible
							  delegate:(id <MADDesignerSectionLayoutLiquidDelegate, UICollectionViewDelegate, UICollectionViewDataSource>)layoutDelegate;

- (void)removeItemAtIndex:(NSIndexPath *)deletePath
				   update:(void (^)(void))update
		animationComplete:(void (^)(BOOL))animationComplete
			   completion:(void (^)(void))completion;

- (void)insertItemAtIndex:(NSIndexPath *)path
				   update:(void (^)(void))update
		animationComplete:(void (^)(BOOL))animationComplete
			   completion:(void (^)(void))completion;

@end

#endif
