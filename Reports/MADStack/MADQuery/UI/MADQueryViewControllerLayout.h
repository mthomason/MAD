//
//  MADQueryViewControllerLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADQueryViewControllerLayoutSection_h
#define MAD_Designer_MADQueryViewControllerLayoutSection_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>
#import "MADIdentifierQueryViewSections.h"

@class NSArray <__covariant ObjectType>;
@class NSSet <__covariant ObjectType>;
@class NSNumber;
@class UITableView;
@class NSIndexPath;
@class NSIndexSet;
@class MADQueryViewControllerLayoutSection;

@protocol MADQueryViewControllerLayoutSectionSelectorProtocol;

@protocol MADQueryViewControllerDatasourceProtocol <NSObject>

    - (void)deleteItemFromQuerySection:(MADIdentifierQueryViewSections)querySection
                         fromTableView:(UITableView *)tableView
                           atIndexPath:(NSIndexPath *)indexPath;

@end

@interface MADQueryViewControllerLayout : NSObject
    
    - (instancetype)initWithNumberOfTables: (NSUInteger)numberOfTables
                          reportingEnabled: (BOOL)reportingEnabled;

    @property (nonatomic, weak) id <MADQueryViewControllerDatasourceProtocol> datasoruce;

    @property (nonatomic, readonly, assign) short count;
    @property (nonatomic, readonly, strong) NSArray <__kindof MADQueryViewControllerLayoutSection *> *sections;

    - (NSSet <NSNumber *> *)sectionTypes;
    - (NSIndexSet *)sectionTypesIndexs;
    - (MADIdentifierQueryViewSections)sectionAtIndex:(short)index;
    - (MADQueryViewControllerLayoutSection *)layoutAtIndex:(short)index;
    
@end

#endif
