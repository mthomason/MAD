//
//  MADQueryViewControllerLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewControllerLayout.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADQueryViewControllerLayoutSections.h"

@interface MADQueryViewControllerLayout ()

    @property (nonatomic, readwrite, assign) short count;
    @property (nonatomic, readwrite, assign) NSUInteger numberOfTables;
    @property (nonatomic, readwrite, strong) NSArray <__kindof MADQueryViewControllerLayoutSection *> *sections;

@end

@implementation MADQueryViewControllerLayout

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

- (MADQueryViewControllerSections)sectionAtIndex:(short)index {
    MADQueryViewControllerLayoutSection *layout = [[MADQueryViewControllerLayoutSection alloc] initWithNumberOfTables:_numberOfTables position:index];
    return layout.querySection;
}

- (NSIndexSet *)sectionTypesIndexs {
    NSMutableIndexSet *sectionTypes = [[NSMutableIndexSet alloc] init];
    NSArray <__kindof MADQueryViewControllerLayoutSection *> *sections = self.sections;
    for (MADQueryViewControllerLayoutSection *section in sections) {
        [sectionTypes addIndex:section.querySection];
    }
    return sectionTypes;
}

- (NSSet <__kindof NSNumber *> *)sectionTypes {
    NSMutableSet <__kindof NSNumber *> *sectionTypes = [[NSMutableSet alloc] initWithCapacity:(NSUInteger)_count];
    for (MADQueryViewControllerLayoutSection *section in self.sections) {
        @autoreleasepool {
            NSNumber *sectionType = [[NSNumber alloc] initWithShort:section.querySection];
            [sectionTypes addObject:sectionType];
        }
    }
    return sectionTypes;
}

- (MADQueryViewControllerLayoutSection *)layoutAtIndex:(short)index {
    return self.sections[(NSUInteger)index];
}

- (NSArray <__kindof MADQueryViewControllerLayoutSection *> *)sections {
    if (_sections != nil) {
        return _sections;
    } else {
        NSMutableArray <__kindof MADQueryViewControllerLayoutSection *> *sections = [[NSMutableArray alloc] initWithCapacity:(NSUInteger)_count];
        for (short i = 0; i < _count; i++) {
            @autoreleasepool {
                MADQueryViewControllerLayoutSection *section = [[MADQueryViewControllerLayoutSection alloc] initWithNumberOfTables:_numberOfTables position:i];
                [sections addObject:section];
            }
        }
        _sections = sections;
        return _sections;
    }
}

@end
