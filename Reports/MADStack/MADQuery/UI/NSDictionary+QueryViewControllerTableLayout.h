//
//  NSDictionary+QueryViewControllerTableLayout.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesigner_NSDictionary__QueryViewControllerTableLayout_h
#define MADDesigner_NSDictionary__QueryViewControllerTableLayout_h

#import <Foundation/NSDictionary.h>

extern NSString * const MTTableHeaderSectionKey;
extern NSString * const MTTableSectionRowKey;
extern NSString * const MTTableSectionRowHeightKey;
extern NSString * const MTTableSectionSectionsKey;

@interface NSDictionary (QueryViewControllerTableLayout)

    + (instancetype)newDictionaryQueryLayoutTableZeroReportingEnabled:(BOOL)reportingEnabled;
    + (instancetype)newDictionaryQueryLayoutTableOneReportingEnabled:(BOOL)reportingEnabled;
    + (instancetype)newDictionaryQueryLayoutTableMoreThanOneReportingEnabled:(BOOL)reportingEnabled;

@end

#endif
