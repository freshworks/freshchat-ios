//
//  HLEventManager.h
//  HotlineSDK
//
//  Created by Harish Kumar on 09/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KonotorDataManager.h"
#import "FDUtilities.h"

//Event plist file path
#define HLEVENT_DIR_PATH @"Hotline/Events"
#define HLEVENT_FILE_NAME @"events.plist" // Hotline/Events/events.plist

//Bulk event dir path
#define BULK_EVENT_DIR_PATH @"bulkevents/"

//bulk event base url for debug mode only
#define HLEVENTS_BULK_BASE_URL @"http://events.staging.konotor.com/bulkevents/"


//Events Name
#define HLEVENT_OPENED_CATEGORY             @"OpenedCategory"
#define HLEVENT_OPENED_ARTICLE              @"OpenedArticle"
#define HLEVENT_FAQ_SEARCH_KEYWORD          @"FAQSearchKeyword"
#define HLEVENT_UPVOTED_ARTICLE             @"UpvotedArticle"
#define HLEVENT_DOWNVOTED_ARTICLE           @"DownvotedArticle"
#define HLEVENT_LAUNCHED_INBOX_FROM_FAQ     @"LaunchedInboxFromFAQ"
#define HLEVENT_SENT_MESSAGE                @"SentMessage"

//Event Params
#define HLEVENT_PARAM_CATEGORY_ID           @"CategoryId"
#define HLEVENT_PARAM_CATEGORY_NAME         @"CategoryName"
#define HLEVENT_PARAM_ARTICLE_NAME          @"ArticleName"
#define HLEVENT_PARAM_ARTICLE_SEARCH_KEY    @"SearchKey"
#define HLEVENT_PARAM_CHANNEL_ID            @"ChannelId"
#define HLEVENT_PARAM_MESSAGE_ID            @"MessageId"
#define HLEVENT_PARAM_ARTICLE_ID            @"ArticleId"

#define HLEVENTS_BATCH_SIZE 50

@interface HLEventManager : NSObject

@property (nonatomic, strong) NSMutableArray *eventsArray;

+ (instancetype)sharedInstance;

//- (void)setEventLibraryPath;

- (void) uploadUserEvents :(NSArray *)events;

+ (NSString *) getUserSessionId;

- (void) getEventsAndUpload;

- (void) updateFileWithEvent :(NSDictionary *) eventDict;

@end
