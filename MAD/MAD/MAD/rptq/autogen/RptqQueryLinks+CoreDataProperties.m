//
//  RptqQueryLinks+CoreDataProperties.m
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryLinks+CoreDataProperties.h"

@implementation RptqQueryLinks (CoreDataProperties)

+ (NSFetchRequest<RptqQueryLinks *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"RptqQueryLinks"];
}

@dynamic designerInitalLayout;
@dynamic designerOriginX;
@dynamic designerOriginY;
@dynamic designerSizeHeight;
@dynamic designerSizeWidth;
@dynamic fieldleft;
@dynamic fieldright;
@dynamic identifier;
@dynamic jointype;
@dynamic jointypeenum;
@dynamic tableleft;
@dynamic tableright;
@dynamic hasLeftField;
@dynamic hasRightField;
@dynamic inQuery;

@end
