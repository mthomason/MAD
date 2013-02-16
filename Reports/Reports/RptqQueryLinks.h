//
//  RptqQueryLinks.h
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
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
@property (nonatomic, retain) NSNumber * designerOriginX;
@property (nonatomic, retain) NSNumber * designerOriginY;
@property (nonatomic, retain) NSNumber * designerSizeWidth;
@property (nonatomic, retain) NSNumber * designerSizeHeight;
@property (nonatomic, retain) NSNumber * designerInitalLayout;
@property (nonatomic, retain) RptqField *hasLeftField;
@property (nonatomic, retain) RptqField *hasRightField;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
