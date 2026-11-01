#include "MCPOPMessageInfo.h"

using namespace mailcore;

void POPMessageInfo::init()
{
    mIndex = 0;
    mSize = 0;
    mUid = NULL;
}

POPMessageInfo::POPMessageInfo()
{
    init();
}

POPMessageInfo::POPMessageInfo(POPMessageInfo * other)
{
    init();
    mIndex = other->mIndex;
    mSize = other->mSize;
    MC_SAFE_REPLACE_COPY(String, mUid, other->mUid);
}

POPMessageInfo::~POPMessageInfo()
{
    MC_SAFE_RELEASE(mUid);
}

String * POPMessageInfo::description()
{
    return String::stringWithUTF8Format("<%s:%p %u %s %u>",
        MCUTF8(className()), this, mIndex, MCUTF8(mUid), mSize);
}

Object * POPMessageInfo::copy()
{
    return new POPMessageInfo(this);
}

void POPMessageInfo::setIndex(unsigned int index)
{
    mIndex = index;
}

unsigned int POPMessageInfo::index()
{
    return mIndex;
}

void POPMessageInfo::setSize(unsigned int size)
{
    mSize = size;
}

unsigned int POPMessageInfo::size()
{
    return mSize;
}

void POPMessageInfo::setUid(String * uid)
{
    MC_SAFE_REPLACE_COPY(String, mUid, uid);
}

String * POPMessageInfo::uid()
{
    return mUid;
}
