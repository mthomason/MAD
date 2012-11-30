//
//  ApplicationPreferences.h
//  Reports
//
//  Created by Michael Thomason on 11/28/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ApplicationPreferences : NSManagedObject

@property (nonatomic, retain) NSNumber * setting1;
@property (nonatomic, retain) NSNumber * setting2;

@end
