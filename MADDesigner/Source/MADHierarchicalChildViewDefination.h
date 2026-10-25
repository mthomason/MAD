//
//  MADQueryVisulizationSchemaDefination.h
//  MAD Designer
//
//  Created by Michael Thomason on 8/30/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_Designer_MADHierarchicalChildViewDefination_h
#define MAD_Designer_MADHierarchicalChildViewDefination_h

#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>

@interface MADHierarchicalChildViewDefination : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign, getter=isRoot) BOOL root;

+ (instancetype)newTableDefination;

@end

#endif
