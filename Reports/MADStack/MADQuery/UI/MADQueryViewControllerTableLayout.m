//
//  MADQueryViewControllerTableLayout.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/11/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryViewControllerTableLayout.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADIdentifierQueryViewSections.h"
#import "NSDictionary+QueryViewControllerTableLayout.h"
#import "MADQueryViewDataSource.h"

@interface MADQueryViewControllerTableLayout ()

    @property (nonatomic, strong) NSDictionary *datamodel;

@end

@implementation MADQueryViewControllerTableLayout

- (void)dealloc {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    _datamodel = nil;
}

- (instancetype)initWithNumberOfTables:(NSInteger)numberOfTables
                      reportingEnabled:(BOOL)enabled {
    
    if (self = [super init]) {
        id result;
        switch (numberOfTables) {
                
            case 0:
                result = [NSDictionary newDictionaryQueryLayoutTableZeroReportingEnabled: enabled];
                break;
                
            case 1:
                result = [NSDictionary newDictionaryQueryLayoutTableOneReportingEnabled: enabled];
                break;
                
            default:
                result = [NSDictionary newDictionaryQueryLayoutTableMoreThanOneReportingEnabled: enabled];
                break;
                
        }
        self.datamodel = result;
    }
    return self;
}

- (NSArray *)sectionTypes {
    id sections = _datamodel[MTTableSectionSectionsKey];
    NSArray *sectionTypes = sections != nil ?
                    [[NSArray alloc] initWithArray: sections] :
                    nil;
    return sectionTypes;
}

@end
