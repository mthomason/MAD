//
//  RptqQuerySort.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery, RptqQueryField;

@interface RptqQuerySort : NSManagedObject

@property (nonatomic, strong) NSNumber * ascending;
@property (nonatomic, strong) NSString * fields;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) RptqQueryField *hasField;
@property (nonatomic, strong) RptqQuery *inQuery;

@end
