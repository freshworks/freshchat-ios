//
//  FDCoreDataImporter.m
//  FreshdeskSDK
//
//  Created by Aravinth Chandran on 05/05/14.
//  Copyright (c) 2014 Freshdesk. All rights reserved.
//

/*
 ===========================================================
 Importing APIs:
 Fetch updates asynchronously and update coredata 
 context on its appropriate thread using preform block,
 Forked main thread back to callee to handle UI.
 =========================================================== 
 */

#import "MobiHelpDatabase.h"
#import "FDFolder.h"
#import "FDArticle.h"
#import "FDTicket.h"
#import "FDCoreDataImporter.h"
#import "FDNote.h"
#import "FDDateUtil.h"
#import "FDSecureStore.h"
#import "FDMacros.h"
#import "FDUtilities.h"
#import "FDError.h"
#import "FDConstants.h"
#import "FDTag.h"
#import "FDAPI.h"
#import "FDCoreDataCoordinator.h"
#import "FDArticleContent.h"

@interface FDCoreDataImporter ()

@property (strong, nonatomic) FDAPIClient           *apiClient;
@property (strong, nonatomic) MobiHelpDatabase       *database;
@property (strong, nonatomic) NSManagedObjectContext *context;
@property (strong, nonatomic) FDSecureStore          *secureStore;

@end

@implementation FDCoreDataImporter

static bool INDEX_INPROGRESS=NO;

-(instancetype)initWithContext:(NSManagedObjectContext *)context webservice:(FDAPIClient *)apiClient{
    self = [super init];
    if (self) {
        self.context = context;
        self.database = [[MobiHelpDatabase alloc] initWithContext:context];
        self.apiClient = apiClient;
        self.secureStore = [FDSecureStore sharedInstance];
    }
    return self;
}

#pragma mark - Solutions Fetching and storing

-(NSURLSessionDataTask *)importAllFoldersWithParam:(NSDictionary *)param completion:(void (^)(NSError *))completion{
    return [self.apiClient fetchAllArticlesWithParams:param completion:^(id fetchedArticles, NSError *error) {
        if (!error) {
            [self broadcastSolutionStateNotification:fetchedArticles];
            [self.context performBlock:^{
                if ([fetchedArticles isKindOfClass:[NSArray class]]) {
                    [self insertArticlesWithInfo:fetchedArticles];
                    [self setIndexingCompleted:NO];
                }else{
                    FDLog(@"SOLUTIONS_IMPORTER: No updates on the server");
                }
            }];
        }
        if( completion){
            [self.context performBlock:^{
                {completion(error);}
            }];
        }
    }];
}

-(void)broadcastSolutionStateNotification:(id)fetchedArticles{
    if ([fetchedArticles count] == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MobiHelp_NoSolutions" object:nil];
    }else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MobiHelp_SolutionsExist" object:nil];
    }
}

-(void)insertArticlesWithInfo:(id)fetchedArticles{
    [self.database deleteAllFolders];
    [self.database deleteAllTags];
    NSArray *categories = fetchedArticles;
    for (int i=0; i<[categories count]; i++) {
        NSDictionary *categoryInfo = categories[i];
        NSArray *folders = [categoryInfo valueForKeyPath:@"category.public_folders"];
        for (int j =0 ; j<[folders count]; j++) {
            NSMutableDictionary *folderInfo  = [NSMutableDictionary dictionaryWithDictionary:folders[j]];
            folderInfo[@"category_name"]     = [categoryInfo valueForKeyPath:@"category.name"];
            folderInfo[@"category_position"] = @(i);
            FDFolder *newFolder = [FDFolder folderWithInfo:folderInfo inManagedObjectContext:self.context];
            NSArray *articles = folderInfo[@"published_articles"];
            for (int k=0; k<[articles count]; k++) {
                
                //Create articles
                NSDictionary *articleInfo = articles[k];
                FDArticle *newArticle = [FDArticle articleWithInfo:articleInfo inManagedObjectContext:self.context];
                [newFolder addArticlesObject:newArticle];

                //Create tags
                NSArray *tags = articleInfo[MOBIHELP_API_RESPONSE_TAGS];
                NSNumber *articleID = articleInfo[@"id"];
                for (int l=0; l<[tags count]; l++) {
                    NSDictionary *tagInfo = tags[l];
                    [FDTag tagForItem:@"FDArticle" WithInfo:tagInfo anditemID:articleID inManagedObjectContext:self.context];
                }
            }
        }
    }
    [self.database saveContextWithDebugMessage:@"Folder Creation"];
}

#pragma mark - Ticket: Create

//When creating a new ticket, create a dummy note which contains the ticket description
-(NSURLSessionDataTask *)createTicketWithContent:(FDTicketContent *)content completion:(void (^)(FDTicket *ticket, NSError *error))completion{
    return [self.apiClient createTicketWithContent:content completion:^(NSDictionary *response, NSError *error) {
        __block FDTicket *newTicket;
        __block NSError *ticketError;
        if (!error) {
            [self.context performBlock:^{
                if(response && [[response valueForKey:@"success"]boolValue]) {
                    newTicket = [FDTicket ticketWithInfo:response inManagedObjectContext:self.context];
                    FDNote *firstNote = [FDNote firstNoteWithEnclosingTicket:newTicket inManagedObjectContext:self.context];
                    if (content.imageData) {
                        firstNote.hasAttachment = @YES;
                        firstNote.attachmentOriginal = content.imageData;
                    }
                    [self generateAutoReplyForTicket:newTicket withDelay:2.0];
                    [self.database saveContextWithDebugMessage:@"Ticket Creation"];
                }
                else { // Empty response or response parsing error
                    ticketError = [[FDError alloc] initWithError:MOBIHELP_ERROR_INVALID_RESPONSE];
                }
            }];
        }else{
            FDLog(@"Failed to create new ticket in the server why ? %@",error);
            ticketError = error;
        }
        dispatch_async(dispatch_get_main_queue(), ^{ if (completion) {completion(newTicket,ticketError);} });
    }];
}

-(void)generateAutoReplyForTicket:(FDTicket *)ticket withDelay:(CGFloat)delay{
    double delayInSeconds   = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.context performBlock:^{
            if ([self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_AUTO_REPLY_ENABLED]) {
                [FDNote autoGeneratedNoteWithEnclosingTicket:ticket inManagedObjectContext:self.context];
                [self.database saveContextWithDebugMessage:@"Auto generated reply."];
            }
        }];
    });
}

-(NSURLSessionDataTask *)updateExistingTicketsWithParam:(NSDictionary *)params completion:(void (^)(NSError *))completion{
    [self.context performBlock:^{
        BOOL isTicketListEmpty = [self.database isTicketEmpty];
        if (!isTicketListEmpty) {
            [self.apiClient fetchAllTicketsWithParams:params completion:^(NSArray *tickets, NSError *error) {
                [self.context performBlock:^{
                    if (!error && [tickets isKindOfClass:[NSArray class]]) {
                        for (int i=0; i<[tickets count]; i++) {
                            NSDictionary *ticketInfo = @{ @"ticket" : tickets[i] };
                            NSArray *notes           = [ticketInfo valueForKeyPath:@"ticket.helpdesk_ticket.notes"];
                            NSSet *insertedNotes     = [self insertNotes:notes withEnclosingTicket:ticketInfo andUnreadState:YES];
                            FDTicket *existingTicket = [self updateTicketWithInfo:ticketInfo];
                            [existingTicket addNotes:insertedNotes];
                        }
                        [self.database saveContextWithDebugMessage:@"Ticket update"];
                    }
                    if (completion){
                        completion(error);
                    }
                }];
            }];
        }else{
            FDError *noTicketsExistError = [[FDError alloc]initWithError:MOBIHELP_NO_TICKET_EXISTS];
            if (completion) {
                completion(noTicketsExistError);
            }
        }
    }];
    return nil;
}

/* Update existing ticket's last updated time & status */
-(FDTicket *)updateTicketWithInfo:(NSDictionary *)ticketInfo{
    FDTicket *existingTicket    = [FDTicket ticketWithInfo:ticketInfo inManagedObjectContext:self.context];
    NSString *updatedDateString = [ticketInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_UPDATED_DATE_PATH];
    NSDate *updatedDate         = [FDDateUtil getRFC3339DateFromString:updatedDateString];
    existingTicket.updatedDate  = updatedDate;
    
    //Update unread count if the new state is resolved .
    NSInteger oldStatus = [existingTicket.status integerValue];
    NSInteger newStatus = [[ticketInfo valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_STATUS_PATH] integerValue];
    if (oldStatus != MOBIHELP_TICKET_STATUS_RESOLVED && newStatus == MOBIHELP_TICKET_STATUS_RESOLVED) {
        NSArray *notes    = [existingTicket.notes allObjects];
        FDNote *firstNote = [notes firstObject];
        firstNote.unread = @YES;
    }
    existingTicket.status = [NSString stringWithFormat:@"%d",(int)newStatus];
    return existingTicket;
}

-(NSMutableSet *)insertNotes:(NSArray *)notes withEnclosingTicket:(NSDictionary *)ticketInfo andUnreadState:(BOOL)unreadState{
    NSMutableSet *insertedNotes = [[NSMutableSet alloc]init];
    for (int i=0; i<[notes count]; i++) {
        NSMutableDictionary *noteInfo = [[NSMutableDictionary alloc]init];
        [noteInfo addEntriesFromDictionary:notes[i]];
        noteInfo[@"unread"] = @(unreadState);
        BOOL isPrivateNote = [[noteInfo valueForKeyPath:@"note.private"]boolValue];
        if (!isPrivateNote){
            FDNote *note = [FDNote noteWithInfo:noteInfo inManagedObjectContext:self.context];
            [insertedNotes addObject:note];
        }
    }
    return insertedNotes;
}

#pragma mark - Notes: Create, Import

-(NSURLSessionDataTask *)createNoteWithContent:(FDNoteContent *)content andParam:(NSDictionary *)params completion:(void (^)(NSError *))completion{
    return [self.apiClient createNoteWithContent:content andParam:params completion:^(NSDictionary *note, NSError *error) {
        if (!error) {
            [self.context performBlock:^{
                FDLog(@"Main thread : %d",[NSThread isMainThread]);
                NSNumber *ticketID   = content.ticketID;
                NSMutableDictionary *noteInfo = [[NSMutableDictionary alloc]init];
                [noteInfo addEntriesFromDictionary:[note valueForKeyPath:@"item"]];
                noteInfo[@"unread"] = @NO;
                FDTicket *existingTicket = [FDTicket getTicketWithID:ticketID inManagedObjectContext:self.context];
                FDNote *newNote = [FDNote noteWithInfo:noteInfo inManagedObjectContext:self.context];
                [existingTicket addNotesObject:newNote];
                if (content.imageData) {
                    newNote.hasAttachment = @YES;
                    newNote.attachmentOriginal = content.imageData;
                }
                [self.database saveContextWithDebugMessage:@"New Note Creation"];
            }];
        }else{
            FDLog(@"Failed to create new note in the server %@",error);
        }
        dispatch_async(dispatch_get_main_queue(), ^{ if (completion) {completion(error);} });
    }];
}

-(NSURLSessionDataTask *)importAllNotesforTicketID:(NSNumber *)ticketID WithParam:(NSDictionary *)param completion:(void (^)(NSError *))completion{
    return [self.apiClient fetchAllNotesforTicketID:ticketID withParams:nil completion:^(NSDictionary *fetchedNotes, NSError *error) {
        if (!error) {
            NSDictionary *enclosingTicket = @{ @"ticket" : fetchedNotes };
            [self.context performBlock:^{
                FDTicket *existingTicket = [FDTicket getTicketWithID:ticketID inManagedObjectContext:self.context];
                existingTicket.status       = [[enclosingTicket valueForKeyPath:MOBIHELP_API_RESPONSE_TICKET_STATUS_PATH] stringValue];
                NSArray *notes           = [fetchedNotes valueForKeyPath:@"helpdesk_ticket.notes"];
                NSSet *insertedNotes     = [self insertNotes:notes withEnclosingTicket:enclosingTicket andUnreadState:NO];
                [existingTicket addNotes:insertedNotes];
                [self.database saveContextWithDebugMessage:nil];
            }];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ if (completion) {completion(error);} });
    }];
}

-(NSURLSessionDataTask *)registerDeviceWithCompletion:(void (^)(NSError *))completion {
    return [self.apiClient registerDeviceWithInfo:[FDUtilities getRegistrationInformation] withCompletion:^(NSDictionary *response, NSError *error){
        if (!error) [self loadDefaultsWithConfig:response];
        completion(error);
    }];
}

-(NSURLSessionDataTask *)registerUserWithCompletion:(void (^)(NSError *))completion {
    return [self.apiClient registerUser:[FDUtilities getRegistrationInformation] completion:^(NSDictionary *response, NSError *error){
        if (!error) [self loadDefaultsWithConfig:response];
        completion(error);
    }];
}

-(NSURLSessionDataTask *)fetchAppConfigWithCompletion:(void (^)(NSError *))completion {
    return [self.apiClient getAppConfigurationWithCompletion:^(NSDictionary *response, NSError *error) {
        if (!error) [self loadDefaultsWithConfig:response];
        completion(error);
    }];
}

-(void)loadDefaultsWithConfig:(NSDictionary *)response{
    BOOL isPaidUser = [[response valueForKeyPath:@"config.acc_status"]boolValue];
    [self.secureStore setBoolValue:isPaidUser forKey:MOBIHELP_DEFAULTS_IS_PAID_USER];
}

-(NSURLSessionDataTask *)closeTicketWithID:(NSNumber *)ticketID completion:(void (^)(NSError *))completion{
    return [self.apiClient closeTicketWithID:ticketID completion:^(NSDictionary *responseObject, NSError *error) {
        if (!error) {
            BOOL isTicketClosed = [responseObject[@"success"]boolValue];
            if (isTicketClosed) {
                FDTicket *ticket = [FDTicket getTicketWithID:ticketID inManagedObjectContext:self.context];
                ticket.status = [NSString stringWithFormat:@"%d",MOBIHELP_TICKET_STATUS_CLOSED];
                [self.database saveContextWithDebugMessage:nil];
                completion(nil);
            }else{
                completion([NSError errorWithDomain:@"Failed to close ticket" code:0 userInfo:nil]);
            }
        }else{
            completion(error);
        }
    }];
}

// Create Index
#pragma Indexing

-(void)updateIndex{
    if(INDEX_INPROGRESS){
        return;
    }
    BOOL indexState = [self.secureStore boolValueForKey:MOBIHELP_DEFAULTS_IS_INDEX_CREATED];
    if (!indexState) {
        [self createIndex];
    }
}

-(void)createIndex{
    INDEX_INPROGRESS = YES;
    [self setIndexingCompleted:NO];
    [self.database deleteAllIndices];
    [self.context performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:MOBIHELP_DB_ARTICLE_ENTITY];
        NSError *error;
        NSArray *results = [self.context executeFetchRequest:request error:&error];
        if (!error) {
            if (results.count > 0) {
                for (int i=0; i<[results count]; i++) {
                    FDArticle *article = results[i];
                    FDArticleContent *articleContent = [[FDArticleContent alloc]initWithArticle:article];
                    [self insertIndexforArticleWithContent:articleContent];
                }
                INDEX_INPROGRESS = NO;
                [self setIndexingCompleted:YES];
                [self.database saveContextWithDebugMessage:@"Index Creation"];
            }
        }else{
            FDLog(@"Failed to create index. %@",error);
        }
    }];
}

-(void)setIndexingCompleted:(BOOL)state{
    [self.secureStore setBoolValue:state forKey:MOBIHELP_DEFAULTS_IS_INDEX_CREATED];
}

-(void)insertIndexforArticleWithContent:(FDArticleContent *)articleContent{
    articleContent.title = [FDUtilities replaceSpecialCharacters:articleContent.title with:@" "];
    articleContent.articleDescription = [FDUtilities replaceSpecialCharacters:articleContent.articleDescription with:@" "];
    NSMutableDictionary *indexInfo = [[NSMutableDictionary alloc] init];
    NSArray *substrings = [articleContent.title componentsSeparatedByString:@" "];
    indexInfo = [self convertIntoDictionary:indexInfo withArray:substrings forLabel:ARTICLE_TITLE and:articleContent.articleID];
    substrings = [articleContent.articleDescription componentsSeparatedByString:@" "];
    indexInfo = [self convertIntoDictionary:indexInfo withArray:substrings forLabel:ARTICLE_DESCRIPTION and:articleContent.articleID];
}

-(NSMutableDictionary *)convertIntoDictionary:(NSMutableDictionary *)indexInfo withArray:(NSArray *)Array forLabel:(NSString *)label and:(NSNumber*)articleID{
    if (Array) {
        FDIndex *index = nil;
        for (int i=0; i < [Array count]; i++) {
            NSString* keyword = Array[i];
            if (keyword.length >= 3) {
                if ([indexInfo objectForKey:keyword]) {
                    index = indexInfo[keyword];
                }else{
                    index = [NSEntityDescription insertNewObjectForEntityForName:MOBIHELP_DB_INDEX_ENTITY inManagedObjectContext:self.context];
                    index.keyWord = keyword;
                    index.articleID = articleID;
                }
                if ([label isEqualToString:ARTICLE_TITLE]) {
                    index.titleMatches = [NSNumber numberWithInt:[index.titleMatches intValue] + 1];
                }else{
                    index.descMatches  =  [NSNumber numberWithInt:[index.descMatches intValue] + 1];
                }
                indexInfo[index.keyWord] = index;
            }
        }
    }
    return indexInfo;
}

@end