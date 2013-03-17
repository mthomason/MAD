//
//  MTReportDesignerDocumentObjectFormat.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTReportDesignerDocumentObjectFormat.h"

@interface MTReportDesignerDocumentObjectFormat ()

@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellDecimals;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellCurrency;
@property (retain, nonatomic) IBOutlet UITableViewCell *tableViewCellCurrencyLocation;


@property (retain, nonatomic) IBOutletCollection(UIView) NSArray *viewsToDisableNumeric;
@property (nonatomic, retain) IBOutletCollection(UIControl) NSArray *controlsToDisableNumeric;
@end

@implementation MTReportDesignerDocumentObjectFormat

- (void)dealloc {
    [_tableViewCellDecimals release];
    [_tableViewCellCurrency release];
    [_tableViewCellCurrencyLocation release];
    [_viewsToDisableNumeric release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)setSelectedDocumentObjects:(NSSet *)objectIds {
    
    BOOL numericTypeInSet = NO;
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];

    for (NSManagedObjectID *objectId in objectIds) {

        RptqDocumentObject *documentObject = [RptqDocumentObject getElementForObjectID:objectId fromObjectContext:managedObjectContext];
        if (MTDataTypeNumber == [[[[documentObject isLabelDataField] referencesField] dataType] integerValue]) {
            numericTypeInSet = YES;
            break;
        }
    }
    for (UIView *view in [self viewsToDisableNumeric]) {
        [view setUserInteractionEnabled:numericTypeInSet];
        if ([view isKindOfClass:[UIControl class]]) {
            [(UIControl *)view setEnabled:numericTypeInSet];
        }
    }

}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewDidUnload {
    [self setViewsToDisableNumeric:nil];
    [self setViewsToDisableNumeric:nil];
    [super viewDidUnload];
}
@end
