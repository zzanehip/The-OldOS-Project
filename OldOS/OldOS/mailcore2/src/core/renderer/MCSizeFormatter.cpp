//
//  MCSizeFormatter.cpp
//  testUI
//
//  Created by DINH Viêt Hoà on 1/29/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCSizeFormatter.h"

#include <math.h>

using namespace mailcore;

String * SizeFormatter::stringWithSize(unsigned int size)
{
    double divider;
    String * unit;
    
    if (size >= 1024 * 1024 * 1024) {
        divider = 1024 * 1024 * 1024;
        unit = MCLOCALIZEDSTRING(MCSTR("GB"));
    }
    else if (size >= 1024 * 1024) {
        divider = 1024 * 1024;
        unit = MCLOCALIZEDSTRING(MCSTR("MB"));
    }
    else if (size >= 1024) {
        divider = 1024;
        unit = MCLOCALIZEDSTRING(MCSTR("KB"));
    }
    else {
        divider = 1;
        unit = MCLOCALIZEDSTRING(MCSTR("bytes"));
    }
    
    if ((size / divider) - round(size / divider) < 0.1) {
        return String::stringWithUTF8Format("%.0f %s", size / divider, unit->UTF8Characters());
    }
    else {
        return String::stringWithUTF8Format("%.1f %s", size / divider, unit->UTF8Characters());
    }
}
