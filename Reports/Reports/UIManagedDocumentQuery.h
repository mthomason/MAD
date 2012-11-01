//
//  UIManagedDocumentQuery.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Constants.h"

@interface UIManagedDocumentQuery : UIManagedDocument

+ (UIManagedDocumentQuery *)activeDocument;
+ (void)setActiveDocument:(UIManagedDocumentQuery *)activeDocument;

@end