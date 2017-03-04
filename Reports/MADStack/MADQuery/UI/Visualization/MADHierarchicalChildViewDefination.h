//
//  MADQueryVisulizationSchemaDefination.h
//  MAD Designer
//
//  Created by Michael Thomason on 8/30/15.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_Designer_MADHierarchicalChildViewDefination_h
#define MAD_Designer_MADHierarchicalChildViewDefination_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@interface MADHierarchicalChildViewDefination : NSObject
    <NSCoding, NSCopying>

    + (instancetype)newTableDefination;

    @property (nonatomic, assign) CGPoint center;
    @property (nonatomic, assign, getter=isRoot) BOOL root;

@end

#endif
