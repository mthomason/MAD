//
//  MUIViewControllerShowSql.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerShowSql.h"

@interface MUIViewControllerShowSql ()

@end

@implementation MUIViewControllerShowSql

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSManagedObjectContext *managedObjectContext = [[UIManagedDocumentReport activeDocument] managedObjectContext];
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    [[self textView] setText:[RptqQuery getSqlForQuery:[[database hasQueries] anyObject]]];    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish:self];
}

- (void)dealloc {
    [_textView release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setTextView:nil];
    [super viewDidUnload];
}
@end
