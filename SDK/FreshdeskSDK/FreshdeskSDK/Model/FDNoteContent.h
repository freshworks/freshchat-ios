//
//  FDNoteContent.h
//  FreshdeskSDK
//
//  Created by AravinthChandran on 30/10/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDNoteContent : NSObject

@property (strong, nonatomic) NSNumber *ticketID;
@property (strong, nonatomic) NSString *body;
@property (strong, nonatomic) NSData  *imageData;

@end
