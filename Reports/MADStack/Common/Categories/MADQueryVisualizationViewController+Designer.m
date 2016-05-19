//
//  MADQueryVisualizationViewController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/6/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationViewController+Designer.h"
#import "UIStoryboard+QueryVisualization.h"

static NSString * const identifier = @"MADStoryboardIDQueryVisulization";

@implementation MADQueryVisualizationViewController (Designer)

+ (instancetype) newQueryVisualizationViewController {
    return [[UIStoryboard QueryVisualization] instantiateViewControllerWithIdentifier:identifier];
}

@end
