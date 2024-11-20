//
//  MADTableViewCellReceiptCharterMember.h
//  MAD Designer
//
//  Created by Michael Thomason on 6/22/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_Designer_MADTableViewCellReceiptCharterMember_h
#define MAD_Designer_MADTableViewCellReceiptCharterMember_h

#import <UIKit/UITableViewCell.h>

@interface MADTableViewCellReceiptCharterMember : UITableViewCell

    @property (weak, nonatomic) IBOutlet UILabel *charterMember;
    @property (weak, nonatomic) IBOutlet UILabel *detail;

@end

#endif
