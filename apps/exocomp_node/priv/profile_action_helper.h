/*
 * SPDX-FileCopyrightText: 2026 Exocomp contributors
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef EXOCOMP_PROFILE_ACTION_HELPER_H
#define EXOCOMP_PROFILE_ACTION_HELPER_H

#include <stddef.h>
#include <stdint.h>

/* The helper reads one request and never accepts command-line arguments. */
#define PAH_MAX_REQUEST_BYTES 4096U
#define PAH_MAX_PROFILE_ID_BYTES 32U
#define PAH_MAX_ACTION_ID_BYTES 64U
#define PAH_MAX_UNIT_BYTES 128U
#define PAH_MAX_COMMAND_OUTPUT_BYTES 1024U

typedef struct {
    uint32_t protocol_version;
    char profile_id[PAH_MAX_PROFILE_ID_BYTES];
    uint32_t profile_version;
    char action_id[PAH_MAX_ACTION_ID_BYTES];
    char target_unit[PAH_MAX_UNIT_BYTES];
} pah_request_t;

typedef enum {
    PAH_OK = 0,
    PAH_ERR_MALFORMED = 1,
    PAH_ERR_MALFORMED_ENCODING = 2,
    PAH_ERR_OVERSIZED = 3,
    PAH_ERR_EXTRA_FIELDS = 4,
    PAH_ERR_UNSUPPORTED_PROTOCOL = 5,
    PAH_ERR_UNKNOWN_PROFILE = 6,
    PAH_ERR_UNSUPPORTED_PROFILE_VERSION = 7,
    PAH_ERR_UNKNOWN_ACTION = 8,
    PAH_ERR_INVALID_TARGET = 9,
    PAH_ERR_UNIT_NOT_LOADED = 10,
    PAH_ERR_UNIT_ACTIVE = 11,
    PAH_ERR_COMMAND_TIMEOUT = 12,
    PAH_ERR_SUBPROCESS_FAILURE = 13,
    PAH_ERR_OUTPUT_LIMIT = 14,
    PAH_ERR_INTERNAL = 15
} pah_result_t;

/*
 * A command runner is injectable solely for unit tests. Production callers
 * pass NULL, which selects the private direct-exec runner in the helper.
 */
typedef enum {
    PAH_COMMAND_OK = 0,
    PAH_COMMAND_TIMEOUT = 1,
    PAH_COMMAND_OUTPUT_LIMIT = 2,
    PAH_COMMAND_ERROR = 3
} pah_command_result_t;

typedef int (*pah_command_runner_fn)(
    const char *const argv[],
    size_t argc,
    char *output,
    size_t output_capacity,
    size_t *output_length,
    unsigned timeout_ms,
    int *exit_code,
    void *context);

pah_result_t pah_parse_request(
    const unsigned char *input,
    size_t input_length,
    pah_request_t *request);

pah_result_t pah_validate_target_unit(const char *unit);
pah_result_t pah_validate_request(const pah_request_t *request);

pah_result_t pah_execute(
    const pah_request_t *request,
    pah_command_runner_fn runner,
    void *runner_context);

const char *pah_result_name(pah_result_t result);

#endif
