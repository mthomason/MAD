//
//  RptqQueryLinks.h
//  Reports
//
//  Created by Michael Thomason on 6/22/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery, RptqQueryField;

@interface RptqQueryLinks : NSManagedObject

@property (nonatomic, retain) NSNumber * designerInitalLayout;
@property (nonatomic, retain) NSNumber * designerOriginX;
@property (nonatomic, retain) NSNumber * designerOriginY;
@property (nonatomic, retain) NSNumber * designerSizeHeight;
@property (nonatomic, retain) NSNumber * designerSizeWidth;
@property (nonatomic, retain) NSString * fieldleft;
@property (nonatomic, retain) NSString * fieldright;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * jointype;
@property (nonatomic, retain) NSNumber * jointypeenum;
@property (nonatomic, retain) NSString * tableleft;
@property (nonatomic, retain) NSString * tableright;
@property (nonatomic, retain) RptqQueryField *hasLeftField;
@property (nonatomic, retain) RptqQueryField *hasRightField;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
