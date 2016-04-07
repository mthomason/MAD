//
//  MADQueryViewControllerLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>

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

@interface MADQueryViewControllerLayoutSection : NSObject
    @property (nonatomic, assign, readonly) MTQuerySections querySection;
    @property (readonly) NSString   *name;
    @property (readonly) NSUInteger count;
    @property (readonly) NSInteger  numberOfRows;
    @property (readonly) CGFloat    height;
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
