
#import <UIKit/UIKit.h>

@interface DocumentStatusView : UIView 

-(void)setDocumentState:(UIDocumentState)documentState;
- (void)setDocumentMessage:(NSString *)message;
- (void)setActivityState:(BOOL)active;

@end
