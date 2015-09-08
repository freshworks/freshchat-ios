//
//  FDTicketContent.h
//  FreshdeskSDK
//
//  Created by Arvchz on 09/04/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FDTicketContent : NSObject

@property (nonatomic, strong) NSNumber *ticketID;
@property (nonatomic, strong) NSString *ticketSubject;
@property (nonatomic, strong) NSString *ticketBody;
@property (strong, nonatomic) NSData  *imageData;

@end
