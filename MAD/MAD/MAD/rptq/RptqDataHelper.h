//
//  RptqDataHelper.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_RptqDataHelper_h
#define Reports_RptqDataHelper_h

#import <Foundation/NSObject.h>

@class NSManagedObjectContext;

@interface RptqDataHelper : NSObject

    + (int64_t)nextIdentifierForClass:(Class)class
        managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    + (void)cleanup;

@end

#endif
