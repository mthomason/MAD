//
//  MADDocumentObjectCachedDataReferenceItem.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentObjectCachedDataReferenceItem_h
#define Reports_MAD_MADDocumentObjectCachedDataReferenceItem_h

#import <Foundation/NSObject.h>

@class MTDatabase;
@class MTDataTable;

@interface MADDocumentObjectCachedDataReferenceItem : NSObject

    - (instancetype)initWithDatabase:(MTDatabase *)database
                           datatable:(MTDataTable *)datatable
                               rowID:(NSUInteger)rowID;

@end

#endif
