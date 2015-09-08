//
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 28/04/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "MobiHelpDatabase.h"
#import "FDMacros.h"
#import "FDTag.h"

@interface MobiHelpDatabase ()


@end

@implementation MobiHelpDatabase

- (instancetype)initWithContext:(NSManagedObjectContext *)context{
    self = [super init];
    if (self) {
        self.context = context;
    }
    return self;
}

-(void)saveContextWithDebugMessage:(NSString *)message{
    NSError *error = nil;
    [self.context save:&error];
    if (!error) {
        FDLog(@"Database: %@ succeded",message);
    }else{
        FDLog(@"Database: %@ failed",message);
    }
}

-(BOOL)isFolderEmpty{
    NSArray *folders = [self fetchAllEntriesOfEntity:MOBIHELP_DB_FOLDER_ENTITY];
    return [folders count] ? NO : YES;
}

-(BOOL)isTicketEmpty{
    NSArray *tickets = [self fetchAllEntriesOfEntity:MOBIHELP_DB_TICKET_ENTITY];
    return [tickets count] ? NO : YES;
}

-(NSInteger)getOverallUnreadNotesCount{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"unread == %d",YES];
    return [[self getNotesForPredicate:predicate]count];
}

-(NSInteger)getUnreadNotesCountForTicketID:(NSNumber *)ticketID{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ticket.ticketID == %@ && unread == %d",ticketID,YES];
    return [[self getNotesForPredicate:predicate]count];
}

-(NSArray *)getAllUnreadNotes{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"unread == %d",YES];
    return [self getNotesForPredicate:predicate];
}

-(NSArray *)getUnreadNotesForTicketID:(NSNumber *)ticketID{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ticket.ticketID == %@ && unread == %d",ticketID,YES];
    return [self getNotesForPredicate:predicate];
}

-(NSArray *)getNotesForPredicate:(NSPredicate *)predicate {
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_NOTE_ENTITY];
    fetchRequest.predicate          = predicate;
    NSArray *matches                = [self.context executeFetchRequest:fetchRequest error:NULL];
    return matches;
}

-(NSArray *)fetchAllEntriesOfEntity:(NSString *)entityName{
    __block NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    __block NSArray *fetchedTuples = [[NSArray alloc] init];
    [self.context performBlockAndWait:^{
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.context];
        NSError *error;
        [fetchRequest setEntity:entity];
        fetchedTuples= [self.context executeFetchRequest:fetchRequest error:&error];
        if (error) {
            FDLog(@"Fetch all entries failed : %@", error);
        }
    }];
    return fetchedTuples ? [NSMutableArray arrayWithArray:fetchedTuples] : nil;
}

-(void)deleteAllEntriesFromEntity:(NSString *)entityName{
    [self.context performBlockAndWait:^{
        NSArray *entries = [self fetchAllEntriesOfEntity:entityName];
        for (int i=0; i<[entries count]; i++) {
            id entry = entries[i];
            [self.context deleteObject:entry];
        }
        NSString *logMessage = [NSString stringWithFormat:@"%@ Entries Deleted",entityName];
        [self saveContextWithDebugMessage:logMessage];
    }];
}

-(void)deleteAllFolders{
    [self deleteAllEntriesFromEntity:MOBIHELP_DB_FOLDER_ENTITY];
}

-(void)deleteAllArticles{
    [self deleteAllEntriesFromEntity:MOBIHELP_DB_ARTICLE_ENTITY];
}

-(void)deleteAllTickets{
    [self deleteAllEntriesFromEntity:MOBIHELP_DB_TICKET_ENTITY];
}

-(void)deleteAllNotes{
    [self deleteAllEntriesFromEntity:MOBIHELP_DB_NOTE_ENTITY];
}

-(void)deleteAllIndices{
    [self deleteAllEntriesFromEntity:MOBIHELP_DB_INDEX_ENTITY];
}

-(void)deleteAllTags{
    [self deleteAllEntriesFromEntity:MOBIHELP_DB_TAG_ENTITY];
}

-(void)deleteEverything{
    [self deleteAllFolders];
    [self deleteAllTickets];
    [self deleteAllIndices];
    [self deleteAllTags];
}

#ifdef DEBUG
-(void)logFolderEntity{
    NSArray *folders = [self fetchAllEntriesOfEntity:MOBIHELP_DB_FOLDER_ENTITY];
    FDLog("\n\n\n");
    FDLog("----------------------------------------------------------------\n");
    FDLog("           \"Core Data Folders Entity Current Status\"\n");
    FDLog("----------------------------------------------------------------\n\n");
    for (FDFolder *folder in folders) {
        FDLog(@"Folder Category: %@\n",folder.categoryName);
        FDLog(@"=========================================");
        FDLog(@"Folder Position: %@\n",folder.position);
        FDLog(@"Category Position: %@\n",folder.categoryPosition);
        FDLog(@"Folder ID: %@\n",folder.folderID);
        FDLog(@"Folder Name: %@\n",folder.name);
        FDLog(@"Folder Description: %@\n",folder.folderDescription);
        FDLog(@"Folder Category ID: %@\n",folder.categoryID);
        FDLog(@"Folder Category Name: %@\n",folder.categoryName);
        FDLog(@"Total Articles in this folder: %lu\n",(unsigned long)[folder.articles count]);
        FDLog("----------------------------------------------------------------\n\n");
    }
    FDLog("--------------------------------END-----------------------------\n\n");

}
#endif

#ifdef DEBUG
-(void)logArticleEntity{
    NSArray *articles = [self fetchAllEntriesOfEntity:MOBIHELP_DB_ARTICLE_ENTITY];
    FDLog("\n\n\n");
    FDLog("----------------------------------------------------------------\n");
    FDLog("           \"Core Data Article Entity Current Status\"\n");
    FDLog("----------------------------------------------------------------\n\n");
    for (FDArticle *article in articles) {
        FDLog(@"Article ID: %@\n",article.articleID);
        FDLog(@"Article Description: %@\n",article.articleDescription);
        FDLog(@"Article Description Plain Text : %@\n",article.descriptionPlainText);
        FDLog(@"Article Title: %@\n",article.title);
        FDLog(@"Article Position: %d\n",[article.position intValue]);
        FDLog(@"Enclosing Folder : %@\n", article.folder);
        FDLog("----------------------------------------------------------------\n\n");
    }
    FDLog("--------------------------------END-----------------------------\n\n");
}
#endif

#ifdef DEBUG
-(void)logTicketEntity{
    NSArray *tickets = [self fetchAllEntriesOfEntity:MOBIHELP_DB_TICKET_ENTITY];
    FDLog("\n\n\n");
    FDLog("----------------------------------------------------------------\n");
    FDLog("           \"Core Data Ticket Entity Current Status\"\n");
    FDLog("----------------------------------------------------------------\n\n");
    for (FDTicket *ticket in tickets) {
        FDLog(@"Ticket ID: %@\n",ticket.ticketID);
        FDLog(@"Ticket Subject: %@\n", ticket.subject);
        FDLog(@"Ticket Description: %@\n",ticket.ticketDescription);
        FDLog(@"Ticket Created Date: %@\n",ticket.createdDate);
        FDLog(@"Ticket Updated Date: %@\n",ticket.updatedDate);
        FDLog(@"Ticket Status: %@\n",ticket.status);
        FDLog(@"Ticket RequesterID %@\n",ticket.userID);
        FDLog(@"Total notes in this ticket %lu\n",(unsigned long)[ticket.notes count]);
        FDLog("----------------------------------------------------------------\n\n");
    }
    FDLog("--------------------------------END-----------------------------\n\n");
}
#endif

#ifdef DEBUG
-(void)logNoteEntity{
    NSArray *notes = [self fetchAllEntriesOfEntity:MOBIHELP_DB_NOTE_ENTITY];
    FDLog("\n\n\n");
    FDLog("--------------------------------------------------------------------------\n");
    FDLog("           \"Core Data Note Entity Current Status\"\n");
    FDLog("--------------------------------------------------------------------------\n\n");
    for (FDNote *note in notes) {
        FDLog(@"Note ID : %@\n",note.noteID);
        FDLog(@"Note Unread State :%@\n",note.unread);
        FDLog(@"Note Body : %@\n",note.body);
        FDLog(@"Note createdDate : %@\n",note.createdDate);
        FDLog(@"Note Incoming : %@\n",note.incoming);
        FDLog(@"Note Source : %@\n",note.source);
        FDLog(@"Note Pending State :%@\n",note.pending);
        if (note.ticket) { FDLog(@"This note is attached to a ticket \n\n"); }
        FDLog("--------------------------------------------------------------------------\n\n");
    }
    FDLog("--------------------------------END-----------------------------\n\n");

}
#endif

#ifdef DEBUG
-(void)logTagEntity{
    NSArray *tags = [self fetchAllEntriesOfEntity:MOBIHELP_DB_TAG_ENTITY];
    FDLog("\n\n\n");
    FDLog("--------------------------------------------------------------------------\n");
    FDLog("           \"Core Data Tag Entity Current Status\"\n");
    FDLog("--------------------------------------------------------------------------\n\n");
    for (FDTag *tag in tags) {
        FDLog(@"Tag Name :%@\n",tag.tagName);
        FDLog(@"Item ID : %@\n",tag.itemID);
        FDLog(@"Item Type : %@\n",tag.itemType);
    }
    FDLog("--------------------------------END-----------------------------\n\n");
}

#endif

#ifdef DEBUG
-(void)logIndexEntity{
    NSArray *indices = [self fetchAllEntriesOfEntity:MOBIHELP_DB_INDEX_ENTITY];
    FDLog("\n\n\n");
    FDLog("--------------------------------------------------------------------------\n");
    FDLog("           \"Core Data Index Entity Current Status\"\n");
    FDLog("--------------------------------------------------------------------------\n\n");
    for (FDIndex* index in indices) {
        FDLog(@"Article ID : %@\n",index.articleID);
        FDLog(@"Word :%@\n",index.keyWord);
        FDLog(@"Occurance in article title : %@\n",index.titleMatches);
        FDLog(@"Occurance in article description : %@\n",index.descMatches);
    }
}
#endif

@end