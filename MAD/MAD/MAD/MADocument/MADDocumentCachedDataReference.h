//
//  MADDocumentCachedDataReference.h
//  MAD
//
//  Created by Michael Thomason on 6/6/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_UIManagedDocument__Extras_h
#define Reports_MAD_UIManagedDocument__Extras_h

#import <Foundation/NSObject.h>

@class NSString;

@interface MADDocumentCachedDataReference : NSObject

    - (instancetype)initWithTableName:(NSString *)tableName
                            fieldName:(NSString *)fieldName
                                rowID:(NSUInteger)rowID;

@end

#endif
