//
//  MTDocumentCellProtocol.h
//  Reports
//
//  Created by Michael Thomason on 5/29/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDocumentCellProtocol_h
#define Reports_MTDocumentCellProtocol_h

#import <Foundation/NSObject.h>

@protocol MTDocumentCellProtocol <NSObject>

    - (void)actionEmail:(id)cell;
    - (void)actionRename:(id)sender;
    - (void)actionDuplicate:(id)sender;
    - (void)actionActivateEditMode:(id)sender;

@end

#endif
