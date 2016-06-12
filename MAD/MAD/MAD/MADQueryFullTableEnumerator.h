//
//  MADQueryFullTableEnumerator.h
//  MAD
//
//  Created by Michael Thomason on 6/10/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RptqDocument;

@interface MADQueryFullTableEnumerator : NSEnumerator

    - (id)initWithDocument:(RptqDocument *)document;

@end
