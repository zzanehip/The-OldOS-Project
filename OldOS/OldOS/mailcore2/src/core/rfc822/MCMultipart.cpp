#include "MCMultipart.h"

#include "MCDefines.h"

using namespace mailcore;

Multipart::Multipart()
{
    init();
}

Multipart::Multipart(Multipart * other) : AbstractMultipart(other)
{
    init();
    setPartID(other->partID());
}

void Multipart::init()
{
    mPartID = NULL;
}

Multipart::~Multipart()
{
    MC_SAFE_RELEASE(mPartID);
}

void Multipart::setPartID(String * partID)
{
    MC_SAFE_REPLACE_COPY(String, mPartID, partID);
}

String * Multipart::partID()
{
    return mPartID;
}

Object * Multipart::copy()
{
    return new Multipart(this);
}

static void * createObject()
{
    return new Multipart();
}

INITIALIZE(Multipart)
{
    Object::registerObjectConstructor("mailcore::Multipart", &createObject);
}
