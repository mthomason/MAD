//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewDataSource.h"

#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryPredicate.h"

#import "MADQueryViewSectionDelegate.h"

#import <CoreData/NSFetchedResultsController.h>

#import <MAD/MADocument.h>

#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqUserCredentals+Extras.h>

#import <Foundation/NSIndexPath.h>
#import <UIKit/UITableView.h>

@interface MADQueryViewDataSource ()
    <NSFetchedResultsControllerDelegate>

    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, readwrite, assign) short count;
    @property (nonatomic, readwrite, assign) NSUInteger numberOfTables;
    @property (nonatomic, readwrite, strong) NSArray <__kindof MADQueryViewSectionDelegate *> *sections;

@end

@implementation MADQueryViewDataSource

- (instancetype)initWithNumberOfTables:(NSUInteger)numberOfTables reportingEnabled:(BOOL)reportingEnabled {

    if (self = [super init]) {
        
        short count;
        switch (numberOfTables) {
            case 0:
                count = reportingEnabled ? 3 : 2;
                break;
            case 1:
                count = reportingEnabled ? 5 : 4;
                break;
            default:
                count = reportingEnabled ? 6 : 5;
                break;
        }
        
        _numberOfTables = numberOfTables;
        _count = count;
        
    }
    return self;
}

- (MADIdentifierQueryViewSections)sectionAtIndex:(short)index {
    MADQueryViewSectionDelegate *layout = [[MADQueryViewSectionDelegate alloc] initWithNumberOfTables:_numberOfTables position:index];
    return layout.querySection;
}

- (NSIndexSet *)sectionTypesIndexs {
    NSMutableIndexSet *sectionTypes = [[NSMutableIndexSet alloc] init];
    NSArray <__kindof MADQueryViewSectionDelegate *> *sections = self.sections;
    for (MADQueryViewSectionDelegate *section in sections) {
        [sectionTypes addIndex:section.querySection];
    }
    return sectionTypes;
}

- (NSSet <__kindof NSNumber *> *)sectionTypes {
    NSMutableSet <__kindof NSNumber *> *sectionTypes = [[NSMutableSet alloc] initWithCapacity:(NSUInteger)_count];
    for (MADQueryViewSectionDelegate *section in self.sections) {
        @autoreleasepool {
            NSNumber *sectionType = [[NSNumber alloc] initWithShort:section.querySection];
            [sectionTypes addObject:sectionType];
        }
    }
    return sectionTypes;
}

- (MADQueryViewSectionDelegate *)layoutAtIndex:(short)index {
    return self.sections[(NSUInteger)index];
}

- (NSArray <__kindof MADQueryViewSectionDelegate *> *)sections {
    if (_sections != nil) {
        return _sections;
    } else {
        NSMutableArray <__kindof MADQueryViewSectionDelegate *> *sections = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)_count];
        for (short i = 0; i < _count; i++) {
            @autoreleasepool {
                MADQueryViewSectionDelegate *section = [[MADQueryViewSectionDelegate alloc] initWithNumberOfTables:_numberOfTables position:i];
                [sections addObject:section];
            }
        }
        _sections = sections;
        return _sections;
    }
}

@end
