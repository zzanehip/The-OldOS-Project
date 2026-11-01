#include "MCSet.h"

#include "MCDefines.h"
#include "MCHashMap.h"
#include "MCString.h"
#include "MCUtils.h"
#include "MCArray.h"
#include "MCLog.h"

using namespace mailcore;

void Set::init()
{
    mHash = new HashMap();
}

Set::Set()
{
    init();
}

Set::Set(Set * o)
{
    init();
    MC_SAFE_REPLACE_COPY(HashMap, mHash, o->mHash);
}

Set::~Set()
{
    delete mHash;
}

Set * Set::set()
{
    Set * result = new Set();
    return (Set *) result->autorelease();
}

Set * Set::setWithArray(Array * objects)
{
    Set * result = new Set();
    result->addObjectsFromArray(objects);
    return (Set *) result->autorelease();
}

String * Set::description()
{
    String * result = String::string();
    result->appendUTF8Format("<%s:%p ", MCUTF8(className()), this);
    result->appendString(mHash->allKeys()->description());
    result->appendUTF8Characters(">");
    return result;
}

Object * Set::copy()
{
    return new Set(this);
}

unsigned int Set::count()
{
    return mHash->count();
}

void Set::addObject(Object * obj)
{
    mHash->setObjectForKey(obj, obj);
}

void Set::removeObject(Object * obj)
{
    mHash->removeObjectForKey(obj);
}

Object * Set::member(Object * obj)
{
    return mHash->objectForKey(obj);
}

bool Set::containsObject(Object * obj)
{
    return (mHash->objectForKey(obj) != NULL);
}

Array * Set::allObjects()
{
    return mHash->allKeys();
}

void Set::removeAllObjects()
{
    mHash->removeAllObjects();
}

void Set::addObjectsFromArray(Array * objects)
{
    if (objects == NULL)
        return;
    
    for(unsigned int i= 0 ; i < objects->count() ; i ++) {
        addObject(objects->objectAtIndex(i));
    }
}

HashMap * Set::serializable()
{
    HashMap * result = Object::serializable();
    result->setObjectForKey(MCSTR("items"), allObjects()->serializable());
    return result;
}

void Set::importSerializable(HashMap * serializable)
{
    Array * array = (Array *) Object::objectWithSerializable((HashMap *) serializable->objectForKey(MCSTR("items")));
    addObjectsFromArray(array);
}

static void * createObject()
{
    return new Set();
}

INITIALIZE(Set)
{
    Object::registerObjectConstructor("mailcore::Set", &createObject);
}
