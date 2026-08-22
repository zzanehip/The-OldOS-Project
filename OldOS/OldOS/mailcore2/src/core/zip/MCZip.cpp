#include "MCWin32.h" // Should be included first.

#include "MCZip.h"
#include "MCZipPrivate.h"

#include "zip.h"
#include "unzip.h"

#include <sys/types.h>
#ifndef _MSC_VER
#include <dirent.h>
#include <unistd.h>
#endif
#include <sys/stat.h>
#include <time.h>

#ifdef _MSC_VER
#define USEWIN32IOAPI
#include "ioapi.h"
#include "iowin32.h"
#endif

using namespace mailcore;

static ErrorCode addFile(zipFile file, String * path);

ErrorCode mailcore::CreateZipFileFromFolder(String * zipFilename, String * path)
{
#ifdef _MSC_VER
    zlib_filefunc64_def ffunc;
    fill_win32_filefunc64A(&ffunc);
    zipFile file = zipOpen2_64(zipFilename->fileSystemRepresentation(), APPEND_STATUS_CREATE, NULL, &ffunc);
#else
    zipFile file = zipOpen(zipFilename->fileSystemRepresentation(), APPEND_STATUS_CREATE);
#endif
    if (file == NULL) {
        return ErrorFile;
    }
    
    addFile(file, path);
    
    int err = zipClose(file, NULL);
    if (err != ZIP_OK) {
        return ErrorFile;
    }
    
    return ErrorNone;
}

static ErrorCode addFile(zipFile file, String * path)
{
    const char * cPath = path->fileSystemRepresentation();
    struct stat statinfo;
    int r;
    int err;
    
    r = stat(cPath, &statinfo);
    if (r < 0)
        return ErrorFile;
    
    if (S_ISDIR(statinfo.st_mode)) {
#ifndef _MSC_VER
        DIR * dir = opendir(cPath);
        if (dir == NULL) {
            return ErrorFile;
        }
        
        struct dirent * ent;
        while ((ent = readdir(dir)) != NULL) {
            if ((strcmp(ent->d_name, ".") == 0) || (strcmp(ent->d_name, "..") == 0)) {
                continue;
            }
            
            String * subpath = path->stringByAppendingPathComponent(String::stringWithFileSystemRepresentation(ent->d_name));
            addFile(file, subpath);
        }
        closedir(dir);
#else
        String * wildcard = path->stringByAppendingPathComponent(MCSTR("*"));

        HANDLE hFind = INVALID_HANDLE_VALUE;
        WIN32_FIND_DATA ffd;

        hFind = FindFirstFile(wildcard->unicodeCharacters(), &ffd);
        if (hFind == INVALID_HANDLE_VALUE)  {
            return ErrorFile;
        }

        do {
            if ((wcscmp(ffd.cFileName, L".") == 0) || (wcscmp(ffd.cFileName, L"..") == 0)) {
                continue;
            }
            String * subpath = path->stringByAppendingPathComponent(String::stringWithCharacters(ffd.cFileName));
            addFile(file, subpath);
        }
        while (FindNextFile(hFind, &ffd) != 0);

        if (GetLastError() != ERROR_NO_MORE_FILES) {
            FindClose(hFind);
            return ErrorFile;
        }

        FindClose(hFind);
#endif

        return ErrorNone;
    }

    time_t clock;
    time(&clock);
    
    struct tm timevalue;
    zip_fileinfo zi;
    gmtime_r(&clock, &timevalue);
    zi.tmz_date.tm_sec = timevalue.tm_sec;
    zi.tmz_date.tm_min = timevalue.tm_min;
    zi.tmz_date.tm_hour = timevalue.tm_hour;
    zi.tmz_date.tm_mday = timevalue.tm_mday;
    zi.tmz_date.tm_mon = timevalue.tm_mon;
    zi.tmz_date.tm_year = timevalue.tm_year;
    zi.internal_fa = 0;
    zi.external_fa = 0;
    zi.dosDate = 0;
    
    err = zipOpenNewFileInZip3(file, path->lastPathComponent()->fileSystemRepresentation(),
        &zi, NULL, 0, NULL, 0, NULL,
        Z_DEFLATED,
        -1, 0,
        -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,
        NULL, 0);
    if (err != ZIP_OK) {
        return ErrorFile;
    }
    
    FILE * f = fopen(cPath, "rb");
    if (f == NULL) {
        return ErrorFile;
    }
    
    char * bytes = (char *) malloc(4096);
    
    size_t count;
    do {
        count = fread(bytes, 1, 4096, f);
        
        err = zipWriteInFileInZip(file, bytes, (unsigned) count);
        if (err != ZIP_OK) {
            free(bytes);
            zipCloseFileInZip(file);
            return ErrorFile;
        }
    } while (count > 0);
    
    free(bytes);
    
    if (ferror(f)) {
        return ErrorFile;
    }
    
    fclose(f);
    
    err = zipCloseFileInZip(file);
    if (err != ZIP_OK) {
        return ErrorFile;
    }
    
    return ErrorNone;
}

#ifndef __APPLE__
String * mailcore::TemporaryDirectoryForZip()
{
    char tempdir[] = "/tmp/mailcore2-XXXXXX";
    char * result = mkdtemp(tempdir);
    if (result == NULL) {
        return NULL;
    }
    return String::stringWithFileSystemRepresentation(tempdir);
}
#endif

String * mailcore::CreateTemporaryZipFileFromFolder(String * folder)
{
    String * tempDirectoryString = TemporaryDirectoryForZip();
    
    if (tempDirectoryString == NULL) {
        return NULL;
    }
    
    String * path = tempDirectoryString->stringByAppendingPathComponent(folder->lastPathComponent())->stringByAppendingUTF8Format(".zip");
    
    ErrorCode err = CreateZipFileFromFolder(path, folder);
    if (err != ErrorNone) {
        return NULL;
    }
    unlink(tempDirectoryString->fileSystemRepresentation());
    
    return path;
}

void mailcore::RemoveTemporaryZipFile(String * zipFilename)
{
    String * tempDir = zipFilename->stringByDeletingLastPathComponent();
    unlink(zipFilename->fileSystemRepresentation());
    unlink(tempDir->fileSystemRepresentation());
}
