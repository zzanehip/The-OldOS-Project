//
//  MCIterator.h
//  mailcore2
//
//  Created by DINH Viêt Hoà on 4/18/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#ifndef MAILCORE_ITERATOR_H

#define MAILCORE_ITERATOR_H

#include <MailCore/MCArray.h>
#include <MailCore/MCHashMap.h>
#include <MailCore/MCIndexSet.h>
#include <MailCore/MCAutoreleasePool.h>
#include <MailCore/MCAssert.h>
#include <string.h>

#ifdef __cplusplus

#define mc_foreacharray(type, __variable, __array) \
type * __variable; \
mailcore::ArrayIterator __variable##__iterator = mailcore::ArrayIteratorInit(__array); \
for (; NULL != (__variable = (type *) mailcore::ArrayIteratorNext(&__variable##__iterator)); )

#define mc_foreacharrayIndex(__index, type, __variable, __array) \
type * __variable; \
mailcore::ArrayIterator __variable##__iterator = mailcore::ArrayIteratorInit(__array); \
for (unsigned int __index = 0; NULL != (__variable = (type *) mailcore::ArrayIteratorNext(&__variable##__iterator)); __index++)

#define mc_foreachhashmapKey(keyType, __key, __hashmap) \
keyType * __key; \
HashMapIterator __key##__iterator = HashMapIteratorInit(__hashmap, true, false); \
while (HashMapIteratorRun(&__key##__iterator)) \
while (HashMapIteratorNext(&__key##__iterator, (Object **) &__key, (Object **) NULL))

#define mc_foreachhashmapValue(valueType, __value, __hashmap) \
valueType * __value; \
HashMapIterator __value##__iterator = HashMapIteratorInit(__hashmap, false, true); \
while (HashMapIteratorRun(&__value##__iterator)) \
while (HashMapIteratorNext(&__value##__iterator, (Object **) NULL, (Object **) &__value))

#define mc_foreachhashmapKeyAndValue(keyType, __key, valueType, __value, __hashmap) \
keyType * __key; \
valueType * __value; \
HashMapIterator __key##__value##__iterator = HashMapIteratorInit(__hashmap, true, true); \
while (HashMapIteratorRun(&__key##__value##__iterator)) \
while (HashMapIteratorNext(&__key##__value##__iterator, (Object **) &__key, (Object **) &__value))

#define mc_foreachindexset(__variable, __indexset) \
int64_t __variable; \
mailcore::IndexSetIterator __variable##__iterator = mailcore::IndexSetIteratorInit(__indexset); \
for (; (__variable = IndexSetIteratorValue(&__variable##__iterator)), IndexSetIteratorIsValid(&__variable##__iterator) ; mailcore::IndexSetIteratorNext(&__variable##__iterator))

namespace mailcore {
    
    struct IndexSetIterator {
        unsigned int rangeIndex;
        unsigned int index;
        Range * currentRange;
        IndexSet * indexSet;
    };
    
    static inline IndexSetIterator IndexSetIteratorInit(IndexSet * indexSet)
    {
        IndexSetIterator iterator = { 0, 0, NULL, indexSet };
        if (indexSet->rangesCount() >= 1) {
            iterator.currentRange = &indexSet->allRanges()[0];
        }
        return iterator;
    }
    
    static inline bool IndexSetIteratorIsValid(IndexSetIterator * iterator)
    {
        return iterator->currentRange != NULL;
    }
    
    static inline int64_t IndexSetIteratorValue(IndexSetIterator * iterator)
    {
        return iterator->currentRange == NULL ? -1 : iterator->currentRange->location + iterator->index;
    }
    
    static inline bool IndexSetIteratorNext(IndexSetIterator * iterator)
    {
        iterator->index ++;
        if (iterator->index > iterator->currentRange->length) {
            // switch to an other range
            iterator->index = 0;
            iterator->rangeIndex ++;
            if (iterator->rangeIndex >= iterator->indexSet->rangesCount()) {
                iterator->currentRange = NULL;
                return false;
            }
            else {
                iterator->currentRange = &iterator->indexSet->allRanges()[iterator->rangeIndex];
                return true;
            }
        }
        else {
            return true;
        }
    }
    
    struct ArrayIterator {
        unsigned index;
        unsigned count;
        Array * array;
    };
    
    static inline ArrayIterator ArrayIteratorInit(Array * array)
    {
        ArrayIterator iterator = { 0, array != NULL ? array->count() : 0, array };
        return iterator;
    }
    
    static inline Object * ArrayIteratorNext(ArrayIterator * iterator)
    {
        if (iterator->index >= iterator->count) {
            return NULL;
        }
        
        Object * result = iterator->array->objectAtIndex(iterator->index);
        ++ iterator->index;
        return result;
    }
    
    
    struct HashMapIterator {
        bool cleanup;
        unsigned index;
        unsigned count;
        Array * keys;
        Array * values;
    };
    
    static inline HashMapIterator HashMapIteratorInit(HashMap * hashmap, bool useKeys, bool useValues)
    {
        AutoreleasePool * pool = new AutoreleasePool();
        Array * keys =  useKeys ? (hashmap != NULL ? hashmap->allKeys() : NULL) : NULL;
        Array * values = useValues ? (hashmap != NULL ? hashmap->allValues() : NULL) : NULL;
        if (keys != NULL) {
            keys->retain();
        }
        if (values != NULL) {
            values->retain();
        }
        HashMapIterator iterator = { false, 0, hashmap != NULL ? hashmap->count() : 0, keys, values };
        pool->release();
        
        return iterator;
    }
    
    static inline bool HashMapIteratorNext(HashMapIterator * iterator, Object ** keyp, Object ** valuep)
    {
        if (iterator->index >= iterator->count) {
            return false;
        }
        
        if (keyp != NULL) {
            MCAssert(iterator->keys != NULL);
            * keyp = iterator->keys->objectAtIndex(iterator->index);
        }
        if (valuep != NULL) {
            MCAssert(iterator->values != NULL);
            * valuep = iterator->values->objectAtIndex(iterator->index);
        }
        iterator->index ++;
        return true;
    }
    
    
    static inline bool HashMapIteratorRun(HashMapIterator * iterator)
    {
        if (!iterator->cleanup) {
            iterator->cleanup = true;
            return true;
        } else {
            MC_SAFE_RELEASE(iterator->keys);
            MC_SAFE_RELEASE(iterator->values);
            return false;
        }
    }
    
};

#endif

#endif
