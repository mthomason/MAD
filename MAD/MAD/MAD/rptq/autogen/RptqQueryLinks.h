//
//  RptqQueryLinks.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqQueryLinks_h
#define MAD_AutoGen_RptqQueryLinks_h

#import <CoreData/NSManagedObject.h>

@class RptqQuery, RptqQueryField;

@interface RptqQueryLinks : NSManagedObject

@property (nonatomic, strong) NSNumber * designerInitalLayout;
@property (nonatomic, strong) NSNumber * designerOriginX;
@property (nonatomic, strong) NSNumber * designerOriginY;
@property (nonatomic, strong) NSNumber * designerSizeHeight;
@property (nonatomic, strong) NSNumber * designerSizeWidth;
@property (nonatomic, strong) NSString * fieldleft;
@property (nonatomic, strong) NSString * fieldright;
@property (nonatomic, strong) NSNumber * identifier;
@property (nonatomic, strong) NSString * jointype;
@property (nonatomic, strong) NSNumber * jointypeenum;
@property (nonatomic, strong) NSString * tableleft;
@property (nonatomic, strong) NSString * tableright;
@property (nonatomic, strong) RptqQueryField *hasLeftField;
@property (nonatomic, strong) RptqQueryField *hasRightField;
@property (nonatomic, strong) RptqQuery *inQuery;

@end

#endif
