//
//  MADQueryViewControllerLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 4/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MTQuerySections) {
    MTQuerySectionsDocumentGroups = 0,
    MTQuerySectionsDatasource = 1,
    MTQuerySectionsTables = 2,
    MTQuerySectionsLinks = 3,
    MTQuerySectionsGroups = 4,
    MTQuerySectionsPredicate = 5,
    MTQuerySectionsSql = 6,
    MTQuerySectionsNumberOfQueryResults = 7
};

@interface MADQueryViewControllerLayout : NSObject

    @property (nonatomic, readonly, strong) NSArray *sections;
    @property (nonatomic, readonly, strong) NSDictionary *headerSectionKeys;
    @property (nonatomic, readonly, strong) NSDictionary *sectionRowKey;
    @property (nonatomic, readonly, strong) NSDictionary *sectionRowHeightKey;

@end
