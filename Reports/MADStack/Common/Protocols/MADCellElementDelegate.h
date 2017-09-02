//
//  MADCellElementDelegate.h
//  MAD Designer
//
//  Created by Michael on 2/9/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADCellElementDelegate_h
#define MADCellElementDelegate_h

#import <MAD/MADDocumentObjectType.h>

@protocol MADCellElementDelegate

    - (void)deleteDocumentObjectRepresentedByCell:(MADCellElement *)cell;
    - (void)editDocumentObjectRepresentedByCell:(MADCellElement *)cell;
    - (void)formatDocumentObjectRepresentedByCell:(MADCellElement *)cell;
    - (MADPrintPageElementType)objectTypeRepresentedByCell:(MADCellElement *)cell;

@end

#endif /* MADCellElementDelegate_h */
