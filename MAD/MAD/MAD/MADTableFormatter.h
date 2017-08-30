//
//  MADTableFormatter.h
//  MAD
//
//  Created by Michael Thomason on 3/22/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADTableFormatter_h
#define MAD_MADTableFormatter_h

#import <MAD/MADDataFormatter.h>

@interface MADTableFormatter : MADDataFormatter

    - (instancetype)initWithQuery:(MTQuery <MADQueryDatabaseProtocol> *)query;

@end

#endif
