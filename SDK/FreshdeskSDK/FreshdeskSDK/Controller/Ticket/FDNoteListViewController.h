//
//  FDNoteListViewController.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 28/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FDGrowingTextView.h"
#import "FDKit.h"
#import "FDTicket.h"
#import "FDTicketStateHandler.h"
#import "FDAttachmentImageViewController.h"
#import "FDCoreDataFetchManager.h"
#import "FDMessagingCell.h"
#import "FDInputToolbarView.h"

@class FDAttachmentImageViewController;

@interface FDNoteListViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    FDTicketStateHandlerDelegate, FDGrowingTextViewDelegate, UITextViewDelegate, CoreDataFetchManagerDelegate, UITableViewDelegate, AttachmentImageControllerDelegate, DeeplinkDelegate, FDInputToolbarViewDelegate>

@property (strong, nonatomic) FDTableView *tableView;

-(instancetype)initWithTicketID:(NSNumber *)ticketID;

@end