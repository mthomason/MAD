//
//  NSManagedObject+Extras.h
//  Reports
//
//  Created by Michael Thomason on 5/20/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Extras)

- (void)obtainPermanentID;
- (BOOL)saveContext;

@end
