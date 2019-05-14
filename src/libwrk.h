#ifndef LIBWRK_H
#define LIBWRK_H

#include "stats.h"
#include "ssl.h"

extern "C"
{

typedef struct config {
    uint64_t connections;
    uint64_t duration;
    uint64_t threads;
    uint64_t timeout;
    uint64_t pipeline;
    bool     delay;
    bool     dynamic;
    bool     latency;
    char    *host;
    char    *script;
    SSL_CTX *ctx;
} cfg;

stats* send_request(
    const char* url,
    const char* method,
    const char** headers,
    int headers_count,
    const char* body,
    stats* stats);

};

#endif