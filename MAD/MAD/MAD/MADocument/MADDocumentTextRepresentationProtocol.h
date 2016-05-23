//
//  MADDocumentTextRepresentationProtocol.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDocumentTextRepresentationProtocol_h
#define MADDocumentTextRepresentationProtocol_h

@protocol MADTextRepresentationProtocol <NSObject>

    @property (nonatomic, assign) NSUInteger elementOffset;
    @property (nonatomic, assign) NSUInteger characterOffset;
    - (NSUInteger)elementCount;
    - (NSUInteger)characterCount;

@end

#endif /* MADDocumentTextRepresentationProtocol_h */
