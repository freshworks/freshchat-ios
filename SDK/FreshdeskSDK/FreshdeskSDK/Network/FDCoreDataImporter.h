//
//  FDCoreDataImporter.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 05/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import "FDAPIClient.h"
#import "FDNoteContent.h"
#import "FDTicketContent.h"
#define ARTICLE_TITLE @"articleTitle"
#define ARTICLE_DESCRIPTION @"articleDescription"

@interface FDCoreDataImporter : NSObject

- (instancetype)initWithContext:(NSManagedObjectContext *)context webservice:(FDAPIClient *)apiClient;

//Device Registration
-(NSURLSessionDataTask *)registerDeviceWithCompletion:(void (^)(NSError *))completion;

//User Registration
-(NSURLSessionDataTask *)registerUserWithCompletion:(void (^)(NSError *))completion;

//Folders
-(NSURLSessionDataTask *)importAllFoldersWithParam:(NSDictionary *)param completion:(void(^)(NSError *error))completion;

//Tickets and Notes
-(NSURLSessionDataTask *)createTicketWithContent:(FDTicketContent *)content completion:(void(^)(FDTicket *ticket, NSError *error))completion;

-(NSURLSessionDataTask *)createNoteWithContent:(FDNoteContent *)content andParam:(NSDictionary *)params completion:(void (^)(NSError *))completion;

-(NSURLSessionDataTask *)importAllNotesforTicketID:(NSNumber *)ticketID WithParam:(NSDictionary *)param completion:(void (^)(NSError *error))completion;

-(NSURLSessionDataTask *)updateExistingTicketsWithParam:(NSDictionary *)params completion:(void (^)(NSError *))completion;

-(NSURLSessionDataTask *)closeTicketWithID:(NSNumber *)ticketID completion:(void (^)(NSError *))completion;

//App Config
-(NSURLSessionDataTask *)fetchAppConfigWithCompletion:(void (^)(NSError *))completion;

//Index
-(void)createIndex;

-(void)updateIndex;

@end
