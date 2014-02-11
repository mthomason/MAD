//
//  UIView+NSObjectIdTag.h
//  Reports
//
//  Created by Michael Thomason on 12/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface UIView (NSObjectIdTag)

@property (nonatomic, retain) NSManagedObjectID *objectIdTag;

//- (UIView *)viewWithTagObjectId:(NSManagedObjectID *)object;

@end
