//
//  MADDesignerElementViewProtocol.h
//  MAD Designer
//
//  Created by Michael on 9/2/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MADDesignerElementViewProtocol_h
#define MADDesignerElementViewProtocol_h

@protocol MADDesignerElementViewProtocol <NSObject>
  @required
    @property (nonatomic, readwrite, assign) BOOL displayWobbling;
    @property (nonatomic, readwrite, assign) BOOL enableResizing;
    @property (nonatomic, readwrite, assign) BOOL displayHighlighted;

@end

#endif /* MADDesignerElementViewProtocol_h */
