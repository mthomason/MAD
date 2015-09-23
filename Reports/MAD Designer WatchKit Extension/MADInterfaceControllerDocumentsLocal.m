//
//  InterfaceController.m
//  MAD Designer WatchKit Extension
//
//  Created by Michael Thomason on 3/31/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADInterfaceControllerDocumentsLocal.h"
#import "MADRowTypeDocumentsLocal.h"
#import "UIColor+EverydayApps.h"
#import "NSFileManager+Common.h"

@interface MADInterfaceControllerDocumentsLocal()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *groupMiddle;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *tableMain;

@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonInfo;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonExport;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonMad;

@property (nonatomic, strong) MADAppConfiguration *app;
@property (nonatomic, strong) NSArray *filesByURL;

@end


@implementation MADInterfaceControllerDocumentsLocal

- (id)init {
    self = [super init];
    
    if (self) {

        Class rowControllerClassDocumentsLocal = [MADRowTypeDocumentsLocal class];
        NSString *identifierRowTypeDocumentLocal = NSStringFromClass(rowControllerClassDocumentsLocal);
        NSArray *rowTypes = @[identifierRowTypeDocumentLocal];
        [self.tableMain setRowTypes:rowTypes];

        NSArray *files = [[NSFileManager defaultManager] contentsOfDocumentsDirectoryWithGroupIdentifier: MADIdentifierGroup
                                                                                            andExtention: MADFileExtentionMobleApplicationDocument];
        
        
        [self.tableMain setNumberOfRows: files.count
                            withRowType: identifierRowTypeDocumentLocal];

        self.filesByURL = files;

    }
    
    return self;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    NSString *MADTitle = @"MAD KPIs";
    NSString *localalizedTitle = NSLocalizedString(MADTitle, MADTitle);
    [self setTitle:localalizedTitle];
    
    NSString *filename;
    MADRowTypeDocumentsLocal *rowController;
    for (NSInteger i=0; i<self.filesByURL.count; i++) {
        filename = ((NSURL *)self.filesByURL[i]).path.lastPathComponent;
        rowController = [self.tableMain rowControllerAtIndex:i];
        [rowController.label setText:filename];
        [rowController.label setTextColor:[UIColor blackColor]];
    }
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    

}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier
                            inTable:(WKInterfaceTable *)table rowIndex:(NSInteger)rowIndex {
    return self.filesByURL.count > 0 ? self.filesByURL[rowIndex] : nil;
}

@end



