//
//  MADReportDesignerSectionElementLayoutManager.h
//  MAD
//
//  Created by Michael Thomason on 11/20/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@interface MADReportDesignerSectionLayoutAttributes : UICollectionViewLayoutAttributes

@property (nonatomic, assign) NSManagedObjectID *objectID;

@end

@class MADReportDesignerSectionElementLayoutManager, RptqDocumentSection;

@protocol MADReportDesignerSectionElementLayoutManagerDelegate <NSObject>

- (void)layoutManager:(MADReportDesignerSectionElementLayoutManager *)layoutManager
      itemNeedsUpdate:(MADReportDesignerSectionLayoutAttributes *)item;

@end

@interface MADReportDesignerSectionElementLayoutManager : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary *items;
@property (nonatomic, weak) id <MADReportDesignerSectionElementLayoutManagerDelegate>delegate;

- (instancetype)initWithDocumentSection:(RptqDocumentSection *)section;
- (void)addItem:(MADReportDesignerSectionLayoutAttributes *)item;
- (void)removeItemWithID:(NSManagedObjectID *)objectID;
- (CGSize)size;
- (void)layout;

@end
