//
//  MUIViewControllerReportDesigner.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerViewController_h
#define Reports_MTReportDesignerViewController_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MAD/MAD.h>
#import <MAD/MTFont.h>
#import <MAD/MADSectionLayoutManager.h>
#import <MAD/NSManagedObject+Extras.h>
#import <MAD/NSManagedObjectID+Extras.h>
#import <MAD/RptqDocumentSectionEnumerator.h>

#import "MADocumentProtocol.h"
#import "MUIViewControllerDelegate.h"
#import "MADViewController.h"
#import "MADViewControllerProtocol.h"

typedef NS_ENUM(NSUInteger, MTToolboxType) {
    MTToolboxTypeElement = 2,
    MTToolboxTypeSection = 3,
    MTToolboxTypeNone = 4,
};

@interface MADDesignerViewController : MADViewController
    <MADocumentProtocol, MADViewControllerProtocol>

@property (nonatomic, weak) IBOutlet id <MTViewControllerProtocol> delegate;
@property (nonatomic, assign) BOOL hidesStatusBar;

- (IBAction)unwindToDesigner:(UIStoryboardSegue *)action;

@end

#endif
