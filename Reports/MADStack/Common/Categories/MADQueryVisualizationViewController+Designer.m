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
static NSString * const QueryVisualization      = @"MADQueryVisualization";

@implementation MADQueryVisualizationViewController (Designer)


+ (instancetype) QueryVisualizationViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName: QueryVisualization bundle: NULL];
    return [sb instantiateViewControllerWithIdentifier: identifier];
}

@end
