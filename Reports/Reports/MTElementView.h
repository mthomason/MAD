//
//  DataObject.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/16/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "UIViewResizeHandle.h"
#import "MTViewBordered.h"

@interface MTElementView : UIView;

- (void)setWobbleRunning:(BOOL)running;
- (BOOL)isWobbleRunning;

- (void)setHighlight:(BOOL)selected;
- (BOOL)highlight;

- (void)setSelected:(BOOL)selected;
- (BOOL)isSelected;

- (id)initWithObjectId:(NSManagedObjectID *)objectId inObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)updateDisplayLabel;

@end