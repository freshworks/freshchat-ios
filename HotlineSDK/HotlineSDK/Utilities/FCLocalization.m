//
//  HLLocalization.m
//  HotlineSDK
//
//  Created by Hrishikesh on 27/05/16.
//  Copyright © 2016 Freshdesk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FCLocalization.h"
#import "FCSecureStore.h"
#import "FCStringUtil.h"

@interface FCLocalization ()
@end

@implementation FCLocalization

+(NSArray *) getBundlePriorityArray{
    NSArray *bundleArray;
    NSMutableArray *priorityArray = [NSMutableArray new];
    NSString *lookupBundleName = [[FCSecureStore sharedInstance]objectForKey:HOTLINE_DEFAULTS_STRINGS_BUNDLE];
    lookupBundleName = lookupBundleName ? lookupBundleName : DEFAULT_BUNDLE_NAME;
    
    NSBundle *overrideBundle = [self bundleWithName:lookupBundleName andLang:[self getPreferredLang]];
    NSBundle *overrideBundleForDefaultLanguage = [self bundleWithName:lookupBundleName andLang:DEFAULT_LANG];
    NSBundle *defaultPodBundleForDefaultLanguage = [self bundleWithName:DEFAULT_BUNDLE_NAME andLang:DEFAULT_LANG];
    
    if(overrideBundle) [priorityArray addObject:overrideBundle];
    if(overrideBundleForDefaultLanguage) [priorityArray addObject:overrideBundleForDefaultLanguage];
    if(defaultPodBundleForDefaultLanguage && ![lookupBundleName isEqualToString:DEFAULT_BUNDLE_NAME]) [priorityArray addObject:defaultPodBundleForDefaultLanguage];
    
    bundleArray = [[NSArray alloc] initWithArray:priorityArray];
    return bundleArray;
}

+(NSString *)localize:(NSString *)key{
    NSString *localizedString;
    //Lookup string in the right order
    for(NSBundle *bundle in [self getBundlePriorityArray]){
        localizedString = NSLocalizedStringWithDefaultValue(key, DEFAULT_LOCALIZATION_TABLE, bundle, nil, nil);
        if([self isLocalizedString:localizedString forKey:key]){
            return localizedString;
        }
    }
    //no match found so return key : This can never happen unless some one deleted the bundle from pod
    return key;
}

+(NSBundle *)bundleWithName:(NSString *)bundleName andLang:(NSString *)langCode{
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:bundleName ofType:@"bundle"]];
    return [NSBundle bundleWithPath:[bundle pathForResource:langCode ofType:@"lproj"]];
}

+(NSString *)getPreferredLang{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0]; //sample "en-US"
    NSDictionary *languageDic = [NSLocale componentsFromLocaleIdentifier:language];
    return [languageDic objectForKey:@"kCFLocaleLanguageCodeKey"]; //sample "en"
}

+(BOOL)isLocalizedString:(NSString *)value forKey:(NSString *)key{
    if (value) {
        return ![key isEqualToString:value];
    }else{
        return NO;
    }
}

+(BOOL) isNotEmpty:(NSString *)key{
    NSString *value = [FCLocalization localize:key];
    return [FCStringUtil isNotEmptyString:value] && [FCLocalization isLocalizedString:value forKey:key];
}

@end
