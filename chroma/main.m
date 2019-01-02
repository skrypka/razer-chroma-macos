//
//  main.m
//  chroma
//
//  Created by Benjamin Dobell on 8/02/2016.
//  Copyright © 2016 Glass Echidna Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GERazerKit.h"

CFStringRef profileName = CFSTR("Chroma");

CFMutableDictionaryRef getFirstProfileWithName(CFArrayRef profiles, CFStringRef name)
{
    CFIndex profileCount = CFArrayGetCount(profiles);
    
    for (CFIndex i = 0; i < profileCount; i++)
    {
        CFStringRef profileName = GERazerMessageDataArrayGetValue(profiles, i, CFSTR("ProfileName"), kGERazerTerminate);
        
        if (CFEqual(profileName, name))
        {
            return (CFMutableDictionaryRef) CFArrayGetValueAtIndex(profiles, i);
        }
    }
    
    return NULL;
}

int main(int argc, const char *argv[])
{
    if (argc != 5) {
        fprintf(stderr, "Usage: ./chroma device_id red green blue\nFor example ./chroma 4 1 0.1 0\n");
        return 1;
    }
    SInt32 connectStatus = GERazerConnect(NULL);
    SInt32 deviceId = atoi(argv[1]);
    float red = atof(argv[2]);
    float green = atof(argv[3]);
    float blue = atof(argv[4]);
    
    if (connectStatus == kGERazerConnectionFailed)
    {
        fprintf(stderr, "Failed to connect to the Razer Device Manager.\n");
        return 1;
    }
    else if (connectStatus == kGERazerConnectionSendOnly)
    {
        fprintf(stderr, "Could only establish 1-way communication with the Razer Device Manager.\n");
        fprintf(stderr, "Please ensure the Synapse Configurator is not running.\n");
        return 1;
    }
    
    NSArray *attachedDevices = (__bridge_transfer NSArray *) GERazerCopyAttachedProductIds();
    
    if ([attachedDevices count] == 0)
    {
        fprintf(stderr, "Unable to detect any attached devices.\n");
        return 2;
    }
    
    SInt32 productId = [attachedDevices[0] intValue];
    NSString *activeProfileId = (__bridge_transfer NSString *) GERazerCopyActiveProfileId(productId);
    
    if (!activeProfileId)
    {
        fprintf(stderr, "Unable to determine the active profile for product id = %d.\n", productId);
        return 2;
    }
    
    CFArrayRef profiles = GERazerCopyProductProfiles(productId);
    
    CFStringRef profileId = NULL;
    CFMutableDictionaryRef profile = getFirstProfileWithName(profiles, profileName);
    
    if (profile)
    {
        profileId = CFDictionaryGetValue(profile, CFSTR("ProfileID"));
        CFRetain(profileId);
    }
    else if (CFArrayGetCount(profiles) > 0)
    {
        CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
        profileId = CFUUIDCreateString(kCFAllocatorDefault, uuid);
        CFRelease(uuid);
        
        CFIndex activeProfileIndex = GERazerProfilesGetIndexForProfileId(profiles, (__bridge CFStringRef) activeProfileId);
        CFDictionaryRef templateProfile = CFArrayGetValueAtIndex(profiles, activeProfileIndex);
        
        profile = GERazerDictionaryCreateMutableDeepCopy(templateProfile);
        CFDictionarySetValue(profile, CFSTR("ProfileName"), profileName);
        CFDictionarySetValue(profile, CFSTR("ProfileID"), profileId);
        
        GERazerSaveProductProfile(productId, profile);
        
        CFRelease(profile);
    }
    
    CFRelease(profiles);
    
    if (!profileId)
    {
        fprintf(stderr, "Uh-oh! This demo isn't clever enough to create a profile from scratch.\nAt least one profile must exist so we can clone it.\n");
        return 2;
    }
    
    if (!CFEqual((__bridge CFStringRef) activeProfileId, profileId))
    {
        GERazerActivateProductProfile(productId, profileId);
    }
    
    SInt32 followingProductId = GERazerGetLedFollowingProductId(productId, profileId);
    
    // Configure effects
    CFMutableDictionaryRef deviceEffects = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    GERazerDictionarySetThenReleaseValue(deviceEffects, kGERazerEffectNameStatic, GERazerEffectCreateStatic(red, green, blue));
    
    CFStringRef deviceIdString = GERazerStringCreateFromInt(deviceId);
    
    CFMutableDictionaryRef effectList = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(effectList, deviceIdString, deviceEffects);
    
    CFRelease(deviceEffects);
    CFRelease(deviceIdString);
    
    CFMutableDictionaryRef deviceSettings = GERazerDeviceSettingsCreateWithLedEffectList(effectList);
    
    CFRelease(effectList);
    
    GERazerDictionaryRecursivelyMergeThenReleaseDictionary(deviceSettings, GERazerDeviceSettingsCreateWithEnabledLightingEffect(deviceId, kGERazerEffectIdStatic, kGERazerLightingBrightnessNormal));
    
    if (followingProductId >= 0)
    {
        GERazerDictionaryRecursivelyMergeThenReleaseDictionary(deviceSettings, GERazerDeviceSettingsCreateWithLedFollowingProduct(followingProductId, false));
    }
    
    GERazerSetProductDeviceSettings(productId, profileId, deviceSettings);
    
    CFRelease(deviceSettings);
    CFRelease(profileId);
    
    printf("Done\n");
    
    return 0;
}
