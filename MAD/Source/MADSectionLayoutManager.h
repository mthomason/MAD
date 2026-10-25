//
//  MADReportDesignerSectionElementLayoutManager.h
//  MAD
//
//  Created by Michael Thomason on 11/20/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADReportDesignerSectionLayoutAttributes_h
#define Reports_MADReportDesignerSectionLayoutAttributes_h

#import <Foundation/NSObject.h>
#import <Foundation/NSValue.h>
#import <CoreGraphics/CGGeometry.h>

@class NSMutableDictionary,
		MADSectionLayoutAttributes, RptqDocumentSection;

@interface MADSectionLayoutManager : NSObject

	- (instancetype)initWithDocumentSection:(RptqDocumentSection *)section;

	@property (nonatomic, strong, readonly) NSMutableDictionary <NSNumber *, MADSectionLayoutAttributes *> *items;
	@property (readonly) CGSize size;

	- (void)addItem:(MADSectionLayoutAttributes *)item;
	- (void)removeItemWithID:(NSNumber *)identifier;
	- (void)layout;
	- (void)positionItem:(MADSectionLayoutAttributes *)placedItem;

@end

#endif
