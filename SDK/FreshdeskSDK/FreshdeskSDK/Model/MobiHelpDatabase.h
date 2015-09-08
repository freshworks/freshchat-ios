//
//  MobiHelpDatabase.h
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 28/04/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

#import "FDArticle.h"
#import "FDFolder.h"
#import "FDTicket.h"
#import "FDIndex.h"
#import "FDNote.h"
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define MOBIHELP_DB_NOTE_ENTITY    @"FDNote"
#define MOBIHELP_DB_TICKET_ENTITY  @"FDTicket"
#define MOBIHELP_DB_ARTICLE_ENTITY @"FDArticle"
#define MOBIHELP_DB_FOLDER_ENTITY  @"FDFolder"
#define MOBIHELP_DB_INDEX_ENTITY   @"FDIndex"
#define MOBIHELP_DB_TAG_ENTITY     @"FDTag"

@interface MobiHelpDatabase : NSObject

@property (strong, nonatomic) NSManagedObjectContext *context;

-(BOOL)isFolderEmpty;
-(BOOL)isTicketEmpty;
- (instancetype)initWithContext:(NSManagedObjectContext *)context;
-(NSArray *)getUnreadNotesForTicketID:(NSNumber *)ticketID;
-(NSInteger)getOverallUnreadNotesCount;
-(NSInteger)getUnreadNotesCountForTicketID:(NSNumber *)ticketID;
-(void)saveContextWithDebugMessage:(NSString *)message;

//Delete
-(void)deleteAllArticles;
-(void)deleteAllFolders;
-(void)deleteAllTickets;
-(void)deleteAllNotes;
-(void)deleteAllIndices;
-(void)deleteAllTags;
-(void)deleteEverything;

//Log
#ifdef DEBUG
-(void)logArticleEntity;
-(void)logFolderEntity;
-(void)logTicketEntity;
-(void)logNoteEntity;
-(void)logIndexEntity;
-(void)logTagEntity;
#endif

@end