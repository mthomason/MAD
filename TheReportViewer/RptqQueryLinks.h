//
//  RptqQueryLinks.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/9/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RptqQuery;

@interface RptqQueryLinks : NSManagedObject

@property (nonatomic, retain) NSString * fieldleft;
@property (nonatomic, retain) NSString * fieldright;
@property (nonatomic, retain) NSString * jointype;
@property (nonatomic, retain) NSString * tableleft;
@property (nonatomic, retain) NSString * tableright;
@property (nonatomic, retain) RptqQuery *inQuery;

@end
