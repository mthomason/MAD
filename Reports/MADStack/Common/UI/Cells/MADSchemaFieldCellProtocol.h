//
//  MADSchemaFieldCellProtocol.h
//  MAD Designer
//
//  Created by Michael on 2/17/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADSchemaFieldCellProtocol_h
#define MADSchemaFieldCellProtocol_h

@protocol MADSchemaFieldCellProtocol
@optional
    - (void)tableViewCell:(MTSchemaFieldCell *)tableViewCell
            didUpdateAnchorPointLeftTo:(CGPoint)anchorPointLeft
                 andAnchorPointRightTo:(CGPoint)anchorPointRight;
@end

#endif /* MADSchemaFieldCellProtocol_h */
