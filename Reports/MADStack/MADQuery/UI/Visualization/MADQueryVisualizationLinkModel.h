//
//  MADQueryVisulizationLinkDefination.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/3/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADQueryVisualizationLinkModel_h
#define MAD_Designer_MADQueryVisualizationLinkModel_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGBase.h>

@class NSURL, MTPair;

@interface MADQueryVisualizationLinkModel : NSObject

	@property (nonatomic, strong) NSURL *linkID;
	@property (nonatomic, strong) MTPair *fieldsIDs;
	@property (nonatomic, strong) MTPair *anchorPoints;
	@property (nonatomic, assign) CGFloat length;

@end

#endif
