//
//  MADQuery+Extras.h
//  MAD
//
//  Created by Michael on 8/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTQuery_Extras_h
#define Reports_MTQuery_Extras_h

#import <MADAPI/MADQuery.h>
#import <MADAPI/MADQueryType.h>

@interface MADQuery (Extras)

    @property (nonatomic, assign, readonly) MADQueryType type;

    - (instancetype)initWithQueryType:(MADQueryType)type object:(id)object;

@end

#endif
