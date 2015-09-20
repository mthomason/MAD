//
//  MTDataTable+Factory.h
//  MAD
//
//  Created by Michael Thomason on 9/18/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <MADFoundation/MTDataTable.h>

@interface MTDataTable (Factory)

+ (instancetype)dataTableFactory:(NSDictionary *)parameters;
+ (instancetype)newDataTableForIdentifier:(NSString *)identifier;

@end
