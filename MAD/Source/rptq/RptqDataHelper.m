//
//  RptqDataHelper.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "RptqDataHelper.h"

@implementation RptqDataHelper

// Identifier allocation moved into RptqStoreContext (insertObjectForEntity:identifier:),
// which mints past the highest identifier an entity already holds.  The old
// nextIdentifierForClass: autoincrement map is gone with Core Data.

+ (void)cleanup { }

@end
