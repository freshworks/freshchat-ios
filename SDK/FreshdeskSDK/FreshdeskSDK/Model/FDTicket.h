//
//  Ticket.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 30/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FDNote;

@interface FDTicket : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * subject;
@property (nonatomic, retain) NSString * ticketDescription;
@property (nonatomic, retain) NSNumber * ticketID;
@property (nonatomic, retain) NSDate * updatedDate;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSSet *notes;
@end

@interface FDTicket (CoreDataGeneratedAccessors)

- (void)addNotesObject:(FDNote *)value;
- (void)removeNotesObject:(FDNote *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

+(FDTicket *)ticketWithInfo:(NSDictionary *)ticketInfo inManagedObjectContext:(NSManagedObjectContext *)context;

+(FDTicket *)getTicketWithID:(NSNumber *)ticketID inManagedObjectContext:(NSManagedObjectContext *)context;


@end
