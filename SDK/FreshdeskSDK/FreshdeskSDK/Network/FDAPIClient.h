//
//  FDAPIClient.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 29/04/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDNoteContent.h"
#import "FDNetworkManager.h"
#import "FDTicketContent.h"

@interface FDAPIClient : NSObject

//User and Device Registration
-(NSURLSessionDataTask *)registerUser:(NSDictionary *)params completion:(void (^)(NSDictionary *response, NSError *error))completion;

-(NSURLSessionDataTask *)registerDeviceWithInfo:(NSDictionary*)params withCompletion:(void(^)(NSDictionary *response, NSError *error))completion;

//Articles
-(NSURLSessionDataTask *)fetchAllArticlesWithParams:(NSDictionary *)params completion:(void(^)(id articles, NSError *error))completion;

//Tickets
-(NSURLSessionDataTask *)createTicketWithContent:(FDTicketContent *)ticketContent completion:(void (^) (NSDictionary *tickets, NSError *error))completion;

-(NSURLSessionDataTask *)fetchAllTicketsWithParams:(NSDictionary *)params completion:(void(^)(NSArray *tickets, NSError *error))completion;

//Notes
-(NSURLSessionDataTask *)createNoteWithContent:(FDNoteContent *)content andParam:(NSDictionary *)params completion:(void (^)(NSDictionary *, NSError *))completion;

-(NSURLSessionDataTask *)fetchAllNotesforTicketID:(NSNumber *)ticketID withParams:(NSDictionary *)params completion:(void(^)(NSDictionary *fetchedNotes, NSError *error))completion;

//Others
-(NSURLSessionDataTask *)getAppConfigurationWithCompletion:(void(^)(NSDictionary *response, NSError *error))completion;

-(NSURLSessionDataTask *)closeTicketWithID:(NSNumber *)ticketID completion:(void (^) (NSDictionary *, NSError *))completion;

@end
