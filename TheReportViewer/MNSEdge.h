//
//  MNSEdge.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/14/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MNSVertex.h"

@interface MNSEdge : NSObject

@property (retain) id container;
@property (retain) MNSVertex *leftVertex;
@property (retain) MNSVertex *rightVertex;

@end