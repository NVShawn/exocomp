/*
 * SPDX-FileCopyrightText: 2026 Exocomp contributors
 * SPDX-License-Identifier: Apache-2.0
 */

#include "profile_action_helper.h"

#include <stdio.h>
#include <string.h>

typedef struct {
    int calls;
    int show_calls;
    int restart_calls;
    int show_command_result;
    int restart_command_result;
    int show_exit_code;
    int restart_exit_code;
    const char *show_output;
    const char *restart_output;
    unsigned show_timeout_ms;
    unsigned restart_timeout_ms;
    char show_argv[8][PAH_MAX_UNIT_BYTES];
    char last_argv[8][PAH_MAX_UNIT_BYTES];
    size_t last_argc;
} fake_runner_t;

static int failures;

#define CHECK(condition)                                                        \
    do {                                                                        \
        if (!(condition)) {                                                     \
            (void)fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, #condition); \
            failures++;                                                         \
        }                                                                       \
    } while (0)

static void check_parse(const char *wire, pah_result_t expected)
{
    pah_request_t request;
    pah_result_t result = pah_parse_request(
        (const unsigned char *)wire, strlen(wire), &request);
    CHECK(result == expected);
}

static void check_parse_bytes(
    const unsigned char *wire,
    size_t wire_length,
    pah_result_t expected)
{
    pah_request_t request;
    pah_result_t result = pah_parse_request(wire, wire_length, &request);
    CHECK(result == expected);
}

static pah_request_t valid_request(void)
{
    pah_request_t request = {
        .protocol_version = 1U,
        .profile_id = "ceph",
        .profile_version = 1U,
        .action_id = "restart_failed_daemon",
        .target_unit = "ceph-osd@1.service"
    };
    return request;
}

static int fake_runner(
    const char *const argv[],
    size_t argc,
    char *output,
    size_t output_capacity,
    size_t *output_length,
    unsigned timeout_ms,
    int *exit_code,
    void *context)
{
    fake_runner_t *fake = context;
    size_t index;
    const char *response;
    int command_result;

    fake->calls++;
    fake->last_argc = argc;
    for (index = 0U; index < argc && index < 8U; index++) {
        (void)snprintf(fake->last_argv[index], sizeof(fake->last_argv[index]), "%s",
                       argv[index]);
    }

    if (argc == 7U && strcmp(argv[1], "show") == 0) {
        fake->show_calls++;
        for (index = 0U; index < argc && index < 8U; index++) {
            (void)snprintf(fake->show_argv[index], sizeof(fake->show_argv[index]), "%s",
                           argv[index]);
        }
        fake->show_timeout_ms = timeout_ms;
        response = fake->show_output == NULL ? "" : fake->show_output;
        command_result = fake->show_command_result;
        *exit_code = fake->show_exit_code;
    } else if (argc == 3U && strcmp(argv[1], "restart") == 0) {
        fake->restart_calls++;
        fake->restart_timeout_ms = timeout_ms;
        response = fake->restart_output == NULL ? "" : fake->restart_output;
        command_result = fake->restart_command_result;
        *exit_code = fake->restart_exit_code;
    } else {
        return PAH_COMMAND_ERROR;
    }

    if (command_result != PAH_COMMAND_OK) {
        return command_result;
    }
    if (strlen(response) > output_capacity) {
        return PAH_COMMAND_OUTPUT_LIMIT;
    }
    memcpy(output, response, strlen(response));
    *output_length = strlen(response);
    return PAH_COMMAND_OK;
}

static void parser_tests(void)
{
    pah_request_t request;
    unsigned char malformed_utf8[] = {
        '1', '\t', 'c', 'e', 'p', 'h', '\t', '1', '\t',
        'r', 'e', 's', 't', 'a', 'r', 't', '_', 'f', 'a', 'i', 'l', 'e', 'd',
        '_', 'd', 'a', 'e', 'm', 'o', 'n', '\t', 'c', 'e', 'p', 'h', '-', 'o',
        's', 'd', '@', 0xff, '1', '.', 's', 'e', 'r', 'v', 'i', 'c', 'e', '\n'
    };
    unsigned char request_with_nul[] = {
        '1', '\t', 'c', 'e', 'p', 'h', '\t', '1', '\t', 'x', '\t', 'c', 'e',
        'p', 'h', '-', 'o', 's', 'd', '@', 0, '1', '.', 's', 'e', 'r', 'v', 'i',
        'c', 'e', '\n'
    };
    unsigned char oversized[PAH_MAX_REQUEST_BYTES + 1U];

    CHECK(pah_parse_request(
              (const unsigned char *)"1\tceph\t1\trestart_failed_daemon\tceph-osd@1.service\n",
              strlen("1\tceph\t1\trestart_failed_daemon\tceph-osd@1.service\n"),
              &request) == PAH_OK);
    CHECK(strcmp(request.profile_id, "ceph") == 0);
    CHECK(strcmp(request.target_unit, "ceph-osd@1.service") == 0);
    CHECK(pah_validate_request(&request) == PAH_OK);

    check_parse("1\tceph\t1\trestart_failed_daemon\tceph-osd@1.service\nextra",
                PAH_ERR_MALFORMED);
    check_parse("1\tceph\t1\trestart_failed_daemon\tceph-osd@1.service\textra\n",
                PAH_ERR_EXTRA_FIELDS);
    check_parse("1\tceph\t1\trestart_failed_daemon\tceph-osd@1.service",
                PAH_ERR_MALFORMED);
    check_parse("1\tceph\t1\trestart_failed_daemon\t\n", PAH_ERR_MALFORMED);
    check_parse((const char *)malformed_utf8, PAH_ERR_MALFORMED_ENCODING);
    check_parse_bytes(request_with_nul, sizeof(request_with_nul), PAH_ERR_MALFORMED_ENCODING);

    memset(oversized, 'a', sizeof(oversized));
    oversized[sizeof(oversized) - 1U] = '\n';
    check_parse((const char *)oversized, PAH_ERR_OVERSIZED);
}

static void validation_tests(void)
{
    pah_request_t request = valid_request();

    request.profile_id[0] = 'x';
    CHECK(pah_validate_request(&request) == PAH_ERR_UNKNOWN_PROFILE);
    request = valid_request();
    (void)snprintf(request.profile_id, sizeof(request.profile_id), "%s", "default");
    CHECK(pah_validate_request(&request) == PAH_ERR_UNKNOWN_PROFILE);
    request = valid_request();
    request.protocol_version = 2U;
    CHECK(pah_validate_request(&request) == PAH_ERR_UNSUPPORTED_PROTOCOL);
    request = valid_request();
    request.profile_version = 2U;
    CHECK(pah_validate_request(&request) == PAH_ERR_UNSUPPORTED_PROFILE_VERSION);
    request = valid_request();
    (void)snprintf(request.action_id, sizeof(request.action_id), "%s", "run_shell");
    CHECK(pah_validate_request(&request) == PAH_ERR_UNKNOWN_ACTION);

    CHECK(pah_validate_target_unit("ceph-osd@12.service") == PAH_OK);
    CHECK(pah_validate_target_unit("ceph-mon@host-a.service") == PAH_OK);
    CHECK(pah_validate_target_unit("ceph-mgr@mgr_1") == PAH_OK);
    CHECK(pah_validate_target_unit("ceph-mds@fs.name.service") == PAH_OK);
    CHECK(pah_validate_target_unit("ceph-radosgw@zone-1.service") == PAH_OK);
    CHECK(pah_validate_target_unit("ceph-crash.service") == PAH_OK);

    CHECK(pah_validate_target_unit("nginx.service") == PAH_ERR_INVALID_TARGET);
    CHECK(pah_validate_target_unit("ceph-osd@1.service;id") == PAH_ERR_INVALID_TARGET);
    CHECK(pah_validate_target_unit("ceph-osd@1$(id).service") == PAH_ERR_INVALID_TARGET);
    CHECK(pah_validate_target_unit("ceph-osd@1|cat.service") == PAH_ERR_INVALID_TARGET);
    CHECK(pah_validate_target_unit("ceph-osd@../1.service") == PAH_ERR_INVALID_TARGET);
    CHECK(pah_validate_target_unit("ceph-osd@one.service") == PAH_ERR_INVALID_TARGET);
    CHECK(pah_validate_target_unit("ceph-osd@.service") == PAH_ERR_INVALID_TARGET);
}

static void execution_tests(void)
{
    pah_request_t request = valid_request();
    fake_runner_t fake = {
        .show_output = "loaded\ninactive\n",
        .restart_output = "",
        .show_exit_code = 0,
        .restart_exit_code = 0
    };
    pah_result_t result;

    result = pah_execute(&request, fake_runner, &fake);
    CHECK(result == PAH_OK);
    CHECK(fake.calls == 2 && fake.show_calls == 1 && fake.restart_calls == 1);
    CHECK(fake.show_timeout_ms == 5000U && fake.restart_timeout_ms == 30000U);
    CHECK(strcmp(fake.show_argv[0], "/usr/bin/systemctl") == 0);
    CHECK(strcmp(fake.show_argv[1], "show") == 0);
    CHECK(strcmp(fake.show_argv[2], "--no-pager") == 0);
    CHECK(strcmp(fake.show_argv[3], "--plain") == 0);
    CHECK(strcmp(fake.show_argv[4], "--property=LoadState,ActiveState") == 0);
    CHECK(strcmp(fake.show_argv[5], "--value") == 0);
    CHECK(strcmp(fake.show_argv[6], "ceph-osd@1.service") == 0);
    CHECK(fake.last_argc == 3U);
    CHECK(strcmp(fake.last_argv[0], "/usr/bin/systemctl") == 0);
    CHECK(strcmp(fake.last_argv[1], "restart") == 0);
    CHECK(strcmp(fake.last_argv[2], "ceph-osd@1.service") == 0);

    fake = (fake_runner_t){.show_output = "loaded\nactive\n", .show_exit_code = 0};
    CHECK(pah_execute(&request, fake_runner, &fake) == PAH_ERR_UNIT_ACTIVE);
    CHECK(fake.calls == 1 && fake.restart_calls == 0);

    fake = (fake_runner_t){.show_output = "loaded\nfailed\n", .show_exit_code = 0};
    CHECK(pah_execute(&request, fake_runner, &fake) == PAH_OK);
    CHECK(fake.restart_calls == 1);

    fake = (fake_runner_t){
        .show_output = "loaded\ninactive\n", .show_command_result = PAH_COMMAND_TIMEOUT
    };
    CHECK(pah_execute(&request, fake_runner, &fake) == PAH_ERR_COMMAND_TIMEOUT);
    CHECK(fake.restart_calls == 0);

    fake = (fake_runner_t){.show_output = "loaded\ninactive\n", .show_exit_code = 1};
    CHECK(pah_execute(&request, fake_runner, &fake) == PAH_ERR_SUBPROCESS_FAILURE);
    CHECK(fake.restart_calls == 0);

    fake = (fake_runner_t){
        .show_output = "loaded\ninactive\n", .restart_command_result = PAH_COMMAND_TIMEOUT
    };
    CHECK(pah_execute(&request, fake_runner, &fake) == PAH_ERR_COMMAND_TIMEOUT);
    CHECK(fake.restart_calls == 1);

    fake = (fake_runner_t){
        .show_output = "loaded\ninactive\n", .restart_exit_code = 1
    };
    CHECK(pah_execute(&request, fake_runner, &fake) == PAH_ERR_SUBPROCESS_FAILURE);
    CHECK(fake.restart_calls == 1);

    fake = (fake_runner_t){.show_output = "not-found\n inactive\n", .show_exit_code = 0};
    CHECK(pah_execute(&request, fake_runner, &fake) == PAH_ERR_UNIT_NOT_LOADED);
}

int main(void)
{
    parser_tests();
    validation_tests();
    execution_tests();

    if (failures != 0) {
        (void)fprintf(stderr, "%d profile-action-helper test(s) failed\n", failures);
        return 1;
    }
    (void)puts("profile-action-helper tests passed");
    return 0;
}
