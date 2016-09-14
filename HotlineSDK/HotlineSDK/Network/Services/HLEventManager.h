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
#define HLEVENT_OPENED_CATEGORY                     @"OpenedCategory"
#define HLEVENT_OPENED_ARTICLE                      @"OpenedArticle"
#define HLEVENT_FAQ_SEARCH_KEYWORD                  @"FAQSearchKeyword"
#define HLEVENT_UPVOTED_ARTICLE                     @"UpvotedArticle"
#define HLEVENT_DOWNVOTED_ARTICLE                   @"DownvotedArticle"
#define HLEVENT_LAUNCH_CHANNELS_VIEW                @"LaunchChannelView"
#define HLEVENT_SENT_MESSAGE                        @"SentMessage"
#define HLEVENT_LAUNCH_FAQ_VIEW                     @"LaunchFAQView"
#define HLEVENT_LAUNCH_CONVERSATION                 @"LaunchConversation"

//Event Params
#define HLEVENT_PARAM_CATEGORY_ID                   @"CategoryId"
#define HLEVENT_PARAM_CATEGORY_NAME                 @"CategoryName"
#define HLEVENT_PARAM_ARTICLE_ID                    @"ArticleId"
#define HLEVENT_PARAM_ARTICLE_NAME                  @"ArticleName"
#define HLEVENT_PARAM_ARTICLE_SEARCH_KEY            @"SearchKey"
#define HLEVENT_PARAM_ARTICLE_SEARCH_COUNT          @"SearchArticleCount"
#define HLEVENT_PARAM_CHANNEL_ID                    @"ChannelId"
#define HLEVENT_PARAM_CHANNEL_NAME                  @"ChannelName"
#define HLEVENT_PARAM_MESSAGE_ID                    @"MessageId"
#define HLEVENT_PARAM_MESSAGE_TYPE                  @"MessageType"
#define HLEVENT_PARAM_OPENED_SOURCE                 @"OpenedSource"

//Events Article Open Source Type
#define HLEVENT_ARTICLE_SOURCE_AS_ARTICLE           @"Article"
#define HLEVENT_ARTICLE_SOURCE_AS_SEARCH            @"SearchArticle"
#define HLEVENT_ARTICLE_SOURCE_AS_DEEPLINK          @"DeepLink"

//Channel launch source
#define HLEVENT_LAUNCH_SOURCE_DEFAULT               @"Default"
#define HLEVENT_INBOX_LAUNCH_SOURCE_ARTICLELIST     @"ArticleList"
#define HLEVENT_INBOX_LAUNCH_SOURCE_FAQLIST         @"FAQList"
#define HLEVENT_INBOX_LAUNCH_SOURCE_ARTICLE_DETAIL  @"ArticleDetail"

//Conversation launch source
#define HLEVENT_CONVERSATION_LAUNCH_CONTACTUS       @"ContactUs"

//Message types
#define HLEVENT_MESSAGE_TYPE_TEXT                   @"Text"
#define HLEVENT_MESSAGE_TYPE_IMAGE                  @"Image"
#define HLEVENT_MESSAGE_TYPE_AUDIO                  @"Image"

#define HLEVENTS_BATCH_SIZE 25

@interface HLEventManager : NSObject

@property (nonatomic, strong) NSMutableArray *eventsArray;

+ (instancetype)sharedInstance;

- (void) uploadUserEvents :(NSArray *)events;

+ (NSString *) getUserSessionId;

- (void)startEventsUploadTimer;

- (void)cancelEventsUploadTimer;

- (void) updateFileWithEvent :(NSDictionary *) eventDict;

@end
