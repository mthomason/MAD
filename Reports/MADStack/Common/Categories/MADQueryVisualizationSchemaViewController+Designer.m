//
//  MADQueryVisualizationSchemaViewController+Designer.m
//  MAD Designer
//
//  Created by Michael Thomason on 6/14/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADQueryVisualizationSchemaViewController+Designer.h"
#import "MADStoryboard.h"

static NSString * const MTQueryBuilderAdvancedSchemaViewControllerIdentifier = @"MTQueryBuilderAdvancedSchemaViewControllerIdentifier";

@implementation MADQueryVisualizationSchemaViewController (Designer)

+ (instancetype)newAdvancedSchemaViewController {
    UIStoryboard *designer = [MADStoryboard storyboardDesigner];
    return [designer instantiateViewControllerWithIdentifier:MTQueryBuilderAdvancedSchemaViewControllerIdentifier];
}

@end
