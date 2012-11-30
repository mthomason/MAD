//
//  User.h
//  Reports
//
//  Created by Michael Thomason on 11/28/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * email;

@end
