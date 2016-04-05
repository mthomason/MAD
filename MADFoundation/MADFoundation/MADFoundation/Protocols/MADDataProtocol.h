//
//  MADDataProtocol.h
//  MAD
//
//  Created by Michael Thomason on 7/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDataProtocol_h
#define MAD_MADDataProtocol_h

@class MTDatabase;

@protocol MADDataProtocol <NSObject>

    - (NSArray *)sortDescriptors;
    - (MTDatabase *)database;

@end

#endif
