//
//  MADTextRepresentationProtocol.h
//  MAD
//
//  Created by Michael Thomason on 10/31/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADTextRepresentationProtocol_h
#define MADTextRepresentationProtocol_h

@protocol MADTextRepresentationProtocol <NSObject>

    @property (nonatomic, assign) NSUInteger elementOffset;
    @property (nonatomic, assign) NSUInteger characterOffset;
    - (NSUInteger)elementCount;
    - (NSUInteger)characterCount;

@end

#endif /* MADTextRepresentationProtocol_h */
