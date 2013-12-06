//
//  AGEncoder.m
//  AeroGear-iOS
//
//  Created by Corinne Krych on 12/6/13.
//  Copyright (c) 2013 JBoss. All rights reserved.
//

#import "AGEncoder.h"


@implementation AGPListEncoder {
    NSPropertyListFormat _format;
}

- (id) init {
    return [self initWithFormat:NSPropertyListXMLFormat_v1_0];
}

- (id) initWithFormat:(NSPropertyListFormat)format {
    if(self = [super init]) {
        _format = format;
    }
    return self;
}

- (NSData *)encode:(id)plist error:(NSError **)error {
    return [NSPropertyListSerialization dataWithPropertyList:plist format:_format
                                                     options:0 error:error];
}

- (id)decode:(NSData *)data error:(NSError **)error {   
    return [NSPropertyListSerialization propertyListWithData:data
                                                     options:NSPropertyListMutableContainersAndLeaves
                                                      format:&_format error:error];
}

- (BOOL)isValid:(id)plist {
    return [NSPropertyListSerialization propertyList:plist isValidForFormat:NSPropertyListXMLFormat_v1_0];
}

@end


@implementation AGJsonEncoder

- (NSData *)encode:(id)plist error:(NSError **)error {
    return [NSJSONSerialization dataWithJSONObject:plist
                                           options:NSJSONWritingPrettyPrinted
                                             error:error];
}

- (id)decode:(NSData *)data error:(NSError **)error {
    id arr = [NSJSONSerialization JSONObjectWithData:data
                                             options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves
                                               error:error];
    
    // cater for iOS 5 returning an 'immutable' array when the size is empty
    if ([arr count] == 0 && ![arr isKindOfClass:[NSMutableArray class]])
        return nil;
    
    return arr;
    
}

- (BOOL)isValid:(id)plist {
    return [NSJSONSerialization isValidJSONObject:plist];
}

@end
