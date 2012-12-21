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

@interface MTCollectionViewSection : UICollectionView
    <UICollectionViewDataSource, UICollectionViewDelegate, ElementViewDelegate>

@property (retain) NSManagedObjectID *objectID;
@property (retain) NSString *localizedName;
@property (assign, getter = isHighlighted) BOOL highlighted;

- (id)initWithFrame:(CGRect)frame name:(NSString *)name andObjectID:(NSManagedObjectID *)objid;
- (NSIndexPath *)indexOfAlienViewWithCenterPoint:(CGPoint)alienCenter;

@end