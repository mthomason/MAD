//
//  MADSchemaFieldCellProtocol.h
//  MAD Designer
//
//  Created by Michael on 2/17/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADSchemaFieldCellProtocol_h
#define MADSchemaFieldCellProtocol_h

@protocol MADSchemaFieldCellProtocol
@optional
- (void)tableViewCell:(MTSchemaFieldCell *)tableViewCell didUpdateAnchorPointLeftTo:(CGPoint)anchorPointLeft andAnchorPointRightTo:(CGPoint)anchorPointRight;
@end

#endif
