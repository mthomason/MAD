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

@class NSArray <__covariant ObjectType>;
@class NSSet <__covariant ObjectType>;
@class NSNumber;
@class NSIndexSet;
@class MADQueryViewControllerLayoutSection;

typedef NS_ENUM(short, MTQuerySections) {
    MTQuerySectionsDocumentGroups = 0,
    MTQuerySectionsDatasource = 1,
    MTQuerySectionsTables = 2,
    MTQuerySectionsLinks = 3,
    MTQuerySectionsGroups = 4,
    MTQuerySectionsPredicate = 5,
    MTQuerySectionsSql = 6,
    MTQuerySectionsNumberOfQueryResults = 7
};

@protocol MADQueryViewControllerLayoutSectionSelectorProtocol <NSObject>

    - (void)addConnection:(id)sender;
    - (void)addTable:(id)sender;
    - (void)addLink:(id)sender;
    - (void)addPredicate:(id)sender;
    - (void)addGroup:(id)sender;

@end

@interface MADQueryViewControllerLayoutSection : NSObject

    @property (nonatomic, assign, readonly) MTQuerySections querySection;
    @property (readonly) NSString   *name;
    @property (readonly) NSUInteger count;
    @property (readonly) NSInteger  numberOfRows;
    @property (readonly) CGFloat    height;
    @property (readonly) SEL        selector;

@end

@interface MADQueryViewControllerLayout : NSObject

    - (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables reportingEnabled:(bool)reportingEnabled;
    @property (nonatomic, readonly, assign) short count;
    @property (nonatomic, readonly, strong) NSArray <__kindof MADQueryViewControllerLayoutSection *> *sections;

    - (NSSet <NSNumber *> *)sectionTypes;
    - (NSIndexSet *)sectionTypesIndexs;
    - (MTQuerySections)sectionAtIndex:(short)index;
    - (MADQueryViewControllerLayoutSection *)layoutAtIndex:(short)index;
    
@end

#endif
