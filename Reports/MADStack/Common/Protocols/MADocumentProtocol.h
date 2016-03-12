//
//  MADocumentProtocol.h
//  MAD Designer
//
//  Created by Michael Thomason on 9/8/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#ifndef MADocumentProtocol_h
#define MADocumentProtocol_h

@class MADocument;

@protocol MADViewControllerDocumentProtocol <NSObject>

@property (nonatomic, weak) MADocument *document;

@end

#endif /* MADocumentProtocol_h */
