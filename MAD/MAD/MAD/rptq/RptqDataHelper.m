//
//  RptqDataHelper.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqDataHelper.h"

#import <objc/objc.h>

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSUUID.h>
#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSExpression.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSExpressionDescription.h>
#import <CoreData/NSFetchRequest.h>

@implementation RptqDataHelper

+ (int64_t)nextIdentifierForClass:(Class)class
             managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSUUID *idn = [NSUUID UUID];
    return (int64_t)idn.hash;
}

- (void)identifier {
    
}

@end
