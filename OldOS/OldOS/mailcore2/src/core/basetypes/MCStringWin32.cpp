#include "MCWin32.h" // Should be included first.

#include "MCString.h"

using namespace mailcore;

#define UUID_STR_LEN 36

String * String::uuidString()
{
    GUID uuid;
    CoCreateGuid(&uuid);
    OLECHAR szGUID[39] = { 0 };
    char uuidString[37] = { 0 };
    StringFromGUID2(uuid, (LPOLESTR)szGUID, 39); // per documentation.
    for(int i = 0; i < UUID_STR_LEN; i++) {
        uuidString[i] = tolower(szGUID[i]);
    }
    return String::stringWithUTF8Characters(uuidString);
}
