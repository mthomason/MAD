//
//  UIScrollViewDashboard.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreData/CoreData.h>
#import "UIColor+EverydayApps.h"

@interface UIScrollViewSection : UIScrollView

@property (retain) NSManagedObjectID *objectID;
@property (retain) NSString *localizedName;
@property (assign, getter = isHighlighted) BOOL highlighted;

- (id)initWithFrame:(CGRect)frame name:(NSString *)name andObjectID:(NSManagedObjectID *)objid;

@end