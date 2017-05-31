//
//  FDLocalNotification.h
//  HotlineSDK
//
//  Created by Aravinth Chandran on 23/09/15.
//  Copyright (c) 2015 Freshdesk. All rights reserved.
//

#ifndef HotlineSDK_FDLocalNotification_h
#define HotlineSDK_FDLocalNotification_h

#define HOTLINE_SOLUTIONS_UPDATED @"com.freshdesk.hotline_solutions_updated"
#define HOTLINE_NETWORK_REACHABLE @"com.freshdesk.hotline_network_reachable"
#define HOTLINE_NETWORK_UNREACHABLE @"com.freshdesk.hotline_network_unreachable"
#define HOTLINE_CHANNELS_UPDATED @"com.freshdesk.hotline_channels_updated"
#define HOTLINE_MESSAGES_DOWNLOADED @"com.freshdesk.hotline_messages_downloaded"
#define HOTLINE_AUDIO_RECORDING_CLOSE @"com.freshdesk.hotline_recording_closed"

#define HOTLINE_AUDIO_MESSAGE_STARTED @"%@_com.freshdesk.hotline_audio_message_started"
#define HOTLINE_AUDIO_MESSAGE_FAILED @"%@_com.freshdesk.hotline_audio_message_failed"
#define HOTLINE_AUDIO_MESSAGE_DOWNLOADED @"%@_com.freshdesk.hotline_audio_message_downloaded"

#define HOTLINE_NOTIFICATION_PERFORM_PENDING_TASKS @"com.freshdesk.notification.perform_pending_tasks"

#define HOTLINE_BANNER_MESSAGE_UPDATED @"com.freshdesk.hotline_banner_message_updated"

@interface FDLocalNotification : NSObject

+(void)post:(NSString *)name;
+(void)post:(NSString *)name info:(id)info;

@end

#endif
