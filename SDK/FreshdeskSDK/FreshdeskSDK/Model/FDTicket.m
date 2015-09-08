//
//  Ticket.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 30/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDTicket.h"
#import "FDNote.h"
#import "FDAPI.h"
#import "MobiHelpDatabase.h"
#import "FDDateUtil.h"

@implementation FDTicket

@dynamic createdDate;
@dynamic status;
@dynamic subject;
@dynamic ticketDescription;
@dynamic ticketID;
@dynamic updatedDate;
@dynamic userID;
@dynamic notes;

/* returns a new ticket if it is not already stored in the database */
+(FDTicket *)ticketWithInfo:(NSDictionary *)ticketInfo inManagedObjectContext:(NSManagedObjectContext *)context{
    NSNumber *ticketID = [ticketInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_ID_PATH];
    FDTicket *existingTicket = [self getTicketWithID:ticketID inManagedObjectContext:context];
    if (existingTicket) {
        return existingTicket;
    }else{
        FDTicket *newTicket         = [NSEntityDescription insertNewObjectForEntityForName:MOBIHELP_DB_TICKET_ENTITY inManagedObjectContext:context];
        newTicket.ticketID          = [ticketInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_ID_PATH];
        newTicket.subject           = [ticketInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_SUBJECT_PATH];
        newTicket.ticketDescription = [ticketInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_DESCRIPTION_PATH];
        newTicket.userID            = [ticketInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_REQUESTER_ID_PATH];
        newTicket.status            = @"2";
        NSString *createdDate       = [ticketInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_CREATED_DATE_PATH];
        NSString *updatedDate       = [ticketInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_UPDATED_DATE_PATH];
        newTicket.createdDate       = [FDDateUtil getRFC3339DateFromString:createdDate];
        newTicket.updatedDate       = [FDDateUtil getRFC3339DateFromString:updatedDate];
        return newTicket;
    }
}

/* Checks for the passed ticketID in the database, returns a ticket if found one */
+(FDTicket *)getTicketWithID:(NSNumber *)ticketID inManagedObjectContext:(NSManagedObjectContext *)context{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_TICKET_ENTITY];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"ticketID == %@",ticketID];
    NSArray *matches             = [context executeFetchRequest:fetchRequest error:nil];
    if ([matches count] > 1) return nil;
    return [matches firstObject];
}

@end