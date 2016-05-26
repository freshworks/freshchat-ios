//
//  HLLocalization.h
//  HotlineSDK
//
//  Created by Hrishikesh on 23/12/15.
//  Copyright © 2015 Freshdesk. All rights reserved.
//

#import "FDUtilities.h"

#ifndef HLLocalization_h
#define HLLocalization_h

static NSString *DEFAULT_LANG = @"en";

#define HLLocalizedString(name) [FDUtilities localize:name]

//Keys to lookup in HLLocalizable.strings
#define LOC_CONTACT_US_BUTTON_TEXT @"contact_us_button_text"

#define LOC_FAQ_CLOSE_BUTTON_TEXT @"faq_close_button_text"
#define LOC_FAQ_TITLE_TEXT @"faq_title_text"

#define LOC_SEARCH_PLACEHOLDER_TEXT @"search_placeholder_text"
#define LOC_SEARCH_EMPTY_RESULT_TEXT @"search_empty_result_text"

#define LOC_MESSAGE_PLACEHOLDER_TEXT @"message_placeholder_text"

#define LOC_EMPTY_CHANNEL_TEXT @"empty_channel_text"
#define LOC_EMPTY_FAQ_TEXT @"empty_faq_text"

#define LOC_CHANNELS_TITLE_TEXT @"channels_title_text"
#define LOC_CHANNELS_CLOSE_BUTTON_TEXT @"channels_close_button_text"

#define LOC_MESSAGES_CLOSE_BUTTON_TEXT @"messages_close_button_text"
#define LOC_MESSAGES_SUPPORT_LABEL_TEXT @"messages_support_label_text"
#define LOC_MESSAGES_USER_LABEL_TEXT @"messages_user_label_text"
#define LOC_DEFAULT_ACTION_BUTTON_TEXT @"default_action_button_text"

#define LOC_EMPTY_MSG_TITLE @"empty_message_title"
#define LOC_EMPTY_MSG_INFO_TEXT @"empty_message_info_text"
#define LOC_MODIFY_PUSH_SETTING_TITLE @"modify_push_setting_title"
#define LOC_MODIFY_PUSH_SETTING_INFO_TEXT @"modify_push_setting_info_text"
#define LOC_MESSAGE_UNSENT_TITLE @"message_unsent_title"
#define LOC_MESSAGE_UNSENT_INFO_TEXT @"message_unsent_info_text"

#define LOC_AUDIO_MSG_TITLE @"audio_message_title"
#define LOC_PICTURE_MSG_TITLE @"picture_message_title"
#define LOC_PICTURE_MSG_UPLOAD_ERROR @"picture_message_upload_error"

#define LOC_AUDIO_RECORDING @"audio_recording"
#define LOC_AUDIO_RECORDING_STOPPED @"audio_recording_stopped"
#define LOC_AUDIO_RECORDING_PERMISSION_DENIED_TEXT @"audio_recording_permission_denied"

#define LOC_AUDIO_SIZE_SHORT_ALERT_TITLE @"short_audio_alert_title"
#define LOC_AUDIO_SIZE_SHORT_ALERT_DESCRIPTION @"short_audio_alert_description_text"
#define LOC_AUDIO_SIZE_LONG_ALERT_TITLE @"long_audio_alert_title"
#define LOC_AUDIO_SIZE_LONG_ALERT_DESCRIPTION @"long_audio_alert_description_text"
#define LOC_AUDIO_SIZE_LONG_ALERT_POST_BUTTON_TITLE @"long_audio_alert_post_button_text"

#define LOC_IMAGE_ATTACHMENT_CANCEL_BUTTON_TEXT @"image_attachment_cancel_button_text"
#define LOC_IMAGE_ATTACHMENT_EXISTING_IMAGE_BUTTON_TEXT @"image_attachment_select_existing_image"
#define LOC_IMAGE_ATTACHMENT_NEW_IMAGE_BUTTON_TEXT @"image_attachment_select_new_image"

#define LOC_CAMERA_UNAVAILABLE_TITLE @"camera_unavailable_title"
#define LOC_CAMERA_UNAVAILABLE_DESCRIPTION @"camera_unavailable_description"
#define LOC_CAMERA_UNAVAILABLE_OK_BUTTON @"camera_unavailable_ok_button_text"
#define LOC_CAMERA_PERMISSION_DENIED_TEXT @"camera_permission_denied"

#define LOC_AUDIO_RECORDING_CANCEL_MESSAGE @"cancel_audio_recording_alert"

#define LOC_SEND_BUTTON_TEXT @"send_button_text"

#define LOC_ARTICLE_VOTE_PROMPT_PARTIAL @"article_vote_prompt"
#define LOC_THANK_YOU_PROMPT_PARTIAL @"thank_you_prompt"
#define LOC_BUTTON_TEXT_PARTIAL @"_%@_button_text"
#define LOC_TEXT_PARTIAL @"_text"

#define LOC_DAY_SUNDAY @"day_sunday"
#define LOC_DAY_MONDAY @"day_monday"
#define LOC_DAY_TUESDAY @"day_tuesday"
#define LOC_DAY_WEDNESDAY @"day_wednesday"
#define LOC_DAY_THURSDAY @"day_thursday"
#define LOC_DAY_FRIDAY @"day_friday"
#define LOC_DAY_SATURDAY @"day_saturday"

#define LOC_DEFAULT_NOTIFICATION_MESSAGE @"notification_message_default"

#define LOC_OFFLINE_MISSING_CONTENT_TEXT @"offline_missing_content_text"

#endif /* HLLocalization_h */
