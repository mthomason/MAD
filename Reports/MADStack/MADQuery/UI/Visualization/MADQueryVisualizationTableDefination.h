//
//  MADQueryVisulizationSchemaDefination.h
//  MAD Designer
//
//  Created by Michael Thomason on 8/30/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADQueryVisualizationTableDefination : NSObject
    <NSCoding, NSCopying>

@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign, getter=isRoot) BOOL root;

@end
