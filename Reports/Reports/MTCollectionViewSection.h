//
//  MTCollectionViewSection.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreData/CoreData.h>
#import "UIColor+EverydayApps.h"
#import "ElementView.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDocumentObject+Extras.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "MUIViewControllerReportDesigner.h"

@interface MTCollectionViewSection : UICollectionView
    <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ElementViewDelegate>

@property (nonatomic, retain) NSManagedObjectID *objectID;
@property (nonatomic, retain) NSString *localizedName;
@property (nonatomic, retain) MUIViewControllerReportDesigner *designerViewController;
@property (assign, getter = isHighlighted) BOOL highlighted;

- (id)initWithFrame:(CGRect)frame name:(NSString *)name andObjectID:(NSManagedObjectID *)objid inDesigner:(MUIViewControllerReportDesigner *)designerViewController;
- (NSIndexPath *)indexOfAlienViewWithCenterPoint:(CGPoint)alienCenter;

@end