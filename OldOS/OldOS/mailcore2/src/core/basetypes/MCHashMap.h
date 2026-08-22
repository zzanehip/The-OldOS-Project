#ifndef MAILCORE_MCHASHMAP_H

#define MAILCORE_MCHASHMAP_H

#include <MailCore/MCObject.h>

#ifdef __cplusplus

namespace mailcore {
    
    class String;
    class Array;
    struct HashMapCell;
    typedef HashMapCell HashMapIter;
    
    class MAILCORE_EXPORT HashMap : public Object {
    public:
        HashMap();
        virtual ~HashMap();
        
        static HashMap * hashMap();
        
        virtual unsigned int count();
        virtual void setObjectForKey(Object * key, Object * value);
        virtual void removeObjectForKey(Object * key);
        virtual Object * objectForKey(Object * key);
        virtual Array * allKeys();
        virtual Array * allValues();
        virtual void removeAllObjects();
        
    public: // subclass behavior
        HashMap(HashMap * o);
        virtual String * description();
        virtual Object * copy();
        virtual HashMap * serializable();
        virtual void importSerializable(HashMap * serializable);
        virtual bool isEqual(Object * otherObject);

    private:
        unsigned int mAllocated;
        unsigned int mCount;
        void ** mCells;
        HashMapIter * iteratorBegin();
        HashMapIter * iteratorNext(HashMapIter * iter);
        void allocate(unsigned int size);
        void init();
    };

}

#endif

#endif
