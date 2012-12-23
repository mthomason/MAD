//
//  RptqQueryLinks.h
//  Reports
//
//  Created by Michael Thomason on 12/23/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqField, RptqQuery;

@interface RptqQueryLinks : NSManagedObject

@property (nonatomic, retain) NSString * fieldleft;
@property (nonatomic, retain) NSString * fieldright;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * jointype;
@property (nonatomic, retain) NSNumber * jointypeenum;
@property (nonatomic, retain) NSString * tableleft;
@property (nonatomic, retain) NSString * tableright;
@property (nonatomic, retain) RptqField *hasLeftField;
@property (nonatomic, retain) RptqField *hasRightField;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
