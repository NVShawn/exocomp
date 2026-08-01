/*
 * SPDX-FileCopyrightText: 2026 Exocomp contributors
 * SPDX-License-Identifier: Apache-2.0
 */

#define _POSIX_C_SOURCE 200809L

#include "profile_action_helper.h"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define PAH_PROTOCOL_VERSION 1U
#define PAH_STATE_TIMEOUT_MS 5000U
#define PAH_RESTART_TIMEOUT_MS 30000U
#define PAH_INPUT_TIMEOUT_MS 5000U

static const char pah_systemctl[] = "/usr/bin/systemctl";

typedef struct {
    const char *id;
    uint32_t version;
    const char *action_id;
} pah_shipped_profile_t;

/* This table is the helper's complete compiled capability inventory. */
static const pah_shipped_profile_t pah_shipped_profiles[] = {
    {"ceph", 1U, "restart_failed_daemon"}
};

static int pah_copy_field(
    const unsigned char *input,
    size_t start,
    size_t length,
    char *destination,
    size_t destination_capacity)
{
    if (length + 1U > destination_capacity) {
        return 0;
    }

    memcpy(destination, input + start, length);
    destination[length] = '\0';
    return 1;
}

static pah_result_t pah_parse_decimal(
    const char *value,
    uint32_t *parsed)
{
    size_t index;
    uint32_t result = 0U;

    if (value[0] == '\0') {
        return PAH_ERR_MALFORMED;
    }

    for (index = 0U; value[index] != '\0'; index++) {
        uint32_t digit;

        if (value[index] < '0' || value[index] > '9') {
            return PAH_ERR_MALFORMED;
        }

        digit = (uint32_t)(value[index] - '0');
        if (result > (UINT32_MAX - digit) / 10U) {
            return PAH_ERR_UNSUPPORTED_PROTOCOL;
        }

        result = result * 10U + digit;
    }

    *parsed = result;
    return PAH_OK;
}

pah_result_t pah_parse_request(
    const unsigned char *input,
    size_t input_length,
    pah_request_t *request)
{
    size_t starts[5];
    size_t lengths[5];
    size_t field = 0U;
    size_t index;
    char protocol_version[16];
    char profile_version[16];
    pah_result_t result;

    if (input == NULL || request == NULL || input_length == 0U) {
        return PAH_ERR_MALFORMED;
    }

    if (input_length > PAH_MAX_REQUEST_BYTES) {
        return PAH_ERR_OVERSIZED;
    }

    if (input[input_length - 1U] != '\n') {
        return PAH_ERR_MALFORMED;
    }

    /* The protocol is intentionally ASCII-only. This rejects malformed UTF-8
     * and also prevents Unicode confusables in IDs and unit names. */
    for (index = 0U; index < input_length; index++) {
        unsigned char byte = input[index];

        if (byte == '\0' || byte >= 0x80U || byte == '\r' ||
            (byte < 0x20U && byte != '\t' && byte != '\n') || byte == 0x7fU) {
            return PAH_ERR_MALFORMED_ENCODING;
        }

        if (byte == '\n' && index != input_length - 1U) {
            return PAH_ERR_EXTRA_FIELDS;
        }
    }

    starts[0] = 0U;
    for (index = 0U; index < input_length - 1U; index++) {
        if (input[index] == '\t') {
            if (field >= 4U) {
                return PAH_ERR_EXTRA_FIELDS;
            }

            lengths[field] = index - starts[field];
            field++;
            starts[field] = index + 1U;
        }
    }

    lengths[field] = (input_length - 1U) - starts[field];
    if (field != 4U) {
        return PAH_ERR_MALFORMED;
    }

    for (index = 0U; index < 5U; index++) {
        if (lengths[index] == 0U) {
            return PAH_ERR_MALFORMED;
        }
    }

    if (!pah_copy_field(input, starts[0], lengths[0], protocol_version,
                        sizeof(protocol_version)) ||
        !pah_copy_field(input, starts[1], lengths[1], request->profile_id,
                        sizeof(request->profile_id)) ||
        !pah_copy_field(input, starts[2], lengths[2], profile_version,
                        sizeof(profile_version)) ||
        !pah_copy_field(input, starts[3], lengths[3], request->action_id,
                        sizeof(request->action_id)) ||
        !pah_copy_field(input, starts[4], lengths[4], request->target_unit,
                        sizeof(request->target_unit))) {
        return PAH_ERR_OVERSIZED;
    }

    result = pah_parse_decimal(protocol_version, &request->protocol_version);
    if (result != PAH_OK) {
        return result;
    }

    result = pah_parse_decimal(profile_version, &request->profile_version);
    if (result != PAH_OK) {
        return result;
    }

    return PAH_OK;
}

static int pah_all_digits(const char *value, size_t length)
{
    size_t index;

    if (length == 0U) {
        return 0;
    }

    for (index = 0U; index < length; index++) {
        if (value[index] < '0' || value[index] > '9') {
            return 0;
        }
    }

    return 1;
}

static int pah_valid_instance(const char *value, size_t length)
{
    size_t index;

    if (length == 0U || length > 64U ||
        !((value[0] >= 'A' && value[0] <= 'Z') ||
          (value[0] >= 'a' && value[0] <= 'z') ||
          (value[0] >= '0' && value[0] <= '9'))) {
        return 0;
    }

    for (index = 0U; index < length; index++) {
        char byte = value[index];
        int alpha = (byte >= 'A' && byte <= 'Z') || (byte >= 'a' && byte <= 'z');
        int digit = byte >= '0' && byte <= '9';

        if (!alpha && !digit && byte != '-' && byte != '_' && byte != '.') {
            return 0;
        }
    }

    return 1;
}

static int pah_has_prefix(const char *value, size_t length, const char *prefix)
{
    size_t prefix_length = strlen(prefix);
    return length > prefix_length && memcmp(value, prefix, prefix_length) == 0;
}

pah_result_t pah_validate_target_unit(const char *unit)
{
    static const char *const instance_prefixes[] = {
        "ceph-osd@",
        "ceph-mon@",
        "ceph-mgr@",
        "ceph-mds@",
        "ceph-radosgw@"
    };
    size_t length;
    size_t index;
    size_t suffix_length = strlen(".service");

    if (unit == NULL) {
        return PAH_ERR_INVALID_TARGET;
    }

    length = strlen(unit);
    if (length == 0U || length >= PAH_MAX_UNIT_BYTES) {
        return PAH_ERR_INVALID_TARGET;
    }

    /* Canonical service units may be supplied with or without the suffix. */
    if (length > suffix_length &&
        memcmp(unit + length - suffix_length, ".service", suffix_length) == 0) {
        length -= suffix_length;
    }

    if (length == 0U) {
        return PAH_ERR_INVALID_TARGET;
    }

    for (index = 0U; index < sizeof(instance_prefixes) / sizeof(instance_prefixes[0]);
         index++) {
        const char *prefix = instance_prefixes[index];
        size_t prefix_length = strlen(prefix);

        if (pah_has_prefix(unit, length, prefix)) {
            size_t instance_length = length - prefix_length;
            const char *instance = unit + prefix_length;

            if (memcmp(prefix, "ceph-osd@", strlen("ceph-osd@")) == 0) {
                return pah_all_digits(instance, instance_length)
                           ? PAH_OK
                           : PAH_ERR_INVALID_TARGET;
            }

            return pah_valid_instance(instance, instance_length)
                       ? PAH_OK
                       : PAH_ERR_INVALID_TARGET;
        }
    }

    /* ceph-crash is a shipped non-instanced daemon unit. */
    if (strcmp(unit, "ceph-crash.service") == 0 ||
        strcmp(unit, "ceph-crash") == 0) {
        return PAH_OK;
    }

    return PAH_ERR_INVALID_TARGET;
}

pah_result_t pah_validate_request(const pah_request_t *request)
{
    size_t index;

    if (request == NULL) {
        return PAH_ERR_MALFORMED;
    }

    if (request->protocol_version != PAH_PROTOCOL_VERSION) {
        return PAH_ERR_UNSUPPORTED_PROTOCOL;
    }

    for (index = 0U;
         index < sizeof(pah_shipped_profiles) / sizeof(pah_shipped_profiles[0]);
         index++) {
        const pah_shipped_profile_t *profile = &pah_shipped_profiles[index];

        if (strcmp(request->profile_id, profile->id) == 0) {
            if (request->profile_version != profile->version) {
                return PAH_ERR_UNSUPPORTED_PROFILE_VERSION;
            }
            if (strcmp(request->action_id, profile->action_id) != 0) {
                return PAH_ERR_UNKNOWN_ACTION;
            }
            return pah_validate_target_unit(request->target_unit);
        }
    }

    return PAH_ERR_UNKNOWN_PROFILE;
}

static int pah_monotonic_millis(uint64_t *value)
{
    struct timespec now;

    if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
        return 0;
    }

    *value = (uint64_t)now.tv_sec * 1000U + (uint64_t)now.tv_nsec / 1000000U;
    return 1;
}

static void pah_kill_and_reap(pid_t child)
{
    int status;

    (void)kill(child, SIGKILL);
    while (waitpid(child, &status, 0) < 0 && errno == EINTR) {
    }
}

static int pah_set_nonblocking(int fd)
{
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) {
        return 0;
    }

    return fcntl(fd, F_SETFL, flags | O_NONBLOCK) == 0;
}

/*
 * Direct, fixed-path systemctl execution. There are no shell-based process
 * APIs, PATH lookup, caller-supplied executable, or inherited environment.
 */
static int pah_direct_command_runner(
    const char *const argv[],
    size_t argc,
    char *output,
    size_t output_capacity,
    size_t *output_length,
    unsigned timeout_ms,
    int *exit_code,
    void *context)
{
    int pipe_fds[2];
    pid_t child;
    int child_status = 0;
    int child_finished = 0;
    int read_open = 1;
    size_t captured = 0U;
    uint64_t deadline;
    (void)context;

    if (argv == NULL || argc == 0U || argv[0] == NULL || output == NULL ||
        output_length == NULL || exit_code == NULL || strcmp(argv[0], pah_systemctl) != 0 ||
        output_capacity == 0U || timeout_ms == 0U ||
        !pah_monotonic_millis(&deadline)) {
        return PAH_COMMAND_ERROR;
    }

    if ((argc == 7U &&
         (strcmp(argv[1], "show") != 0 || strcmp(argv[2], "--no-pager") != 0 ||
          strcmp(argv[3], "--plain") != 0 ||
          strcmp(argv[4], "--property=LoadState,ActiveState") != 0 ||
          strcmp(argv[5], "--value") != 0 || pah_validate_target_unit(argv[6]) != PAH_OK)) ||
        (argc == 3U &&
         (strcmp(argv[1], "restart") != 0 || pah_validate_target_unit(argv[2]) != PAH_OK)) ||
        (argc != 7U && argc != 3U)) {
        return PAH_COMMAND_ERROR;
    }

    if (UINT64_MAX - deadline < (uint64_t)timeout_ms) {
        deadline = UINT64_MAX;
    } else {
        deadline += (uint64_t)timeout_ms;
    }

    if (pipe(pipe_fds) != 0) {
        return PAH_COMMAND_ERROR;
    }

    child = fork();
    if (child < 0) {
        (void)close(pipe_fds[0]);
        (void)close(pipe_fds[1]);
        return PAH_COMMAND_ERROR;
    }

    if (child == 0) {
        char *exec_argv[8];
        char *const clean_environment[] = {
            (char *)"PATH=/usr/bin:/bin",
            (char *)"SYSTEMD_PAGER=cat",
            (char *)"SYSTEMD_PAGERSECURE=1",
            (char *)"SYSTEMD_COLORS=0",
            (char *)"LC_ALL=C",
            NULL
        };
        size_t index;

        (void)close(pipe_fds[0]);
        if (dup2(pipe_fds[1], STDOUT_FILENO) < 0 ||
            dup2(pipe_fds[1], STDERR_FILENO) < 0) {
            _exit(126);
        }
        (void)close(pipe_fds[1]);

        for (index = 0U; index < argc && index < sizeof(exec_argv) / sizeof(exec_argv[0]) - 1U;
             index++) {
            exec_argv[index] = (char *)argv[index];
        }
        if (index != argc) {
            _exit(126);
        }
        exec_argv[index] = NULL;

        execve(pah_systemctl, exec_argv, clean_environment);
        _exit(127);
    }

    (void)close(pipe_fds[1]);
    if (!pah_set_nonblocking(pipe_fds[0])) {
        (void)close(pipe_fds[0]);
        pah_kill_and_reap(child);
        return PAH_COMMAND_ERROR;
    }

    while (read_open || !child_finished) {
        unsigned char buffer[256];
        ssize_t read_count;
        uint64_t now;
        int poll_timeout;
        struct pollfd poll_fd;

        if (read_open) {
            do {
                read_count = read(pipe_fds[0], buffer, sizeof(buffer));
            } while (read_count < 0 && errno == EINTR);

            if (read_count > 0) {
                if (captured + (size_t)read_count > output_capacity) {
                    (void)close(pipe_fds[0]);
                    pah_kill_and_reap(child);
                    return PAH_COMMAND_OUTPUT_LIMIT;
                }
                memcpy(output + captured, buffer, (size_t)read_count);
                captured += (size_t)read_count;
            } else if (read_count == 0) {
                read_open = 0;
            } else if (errno != EAGAIN && errno != EWOULDBLOCK) {
                (void)close(pipe_fds[0]);
                pah_kill_and_reap(child);
                return PAH_COMMAND_ERROR;
            }
        }

        if (!child_finished) {
            pid_t waited = waitpid(child, &child_status, WNOHANG);
            if (waited == child) {
                child_finished = 1;
            } else if (waited < 0 && errno != EINTR) {
                (void)close(pipe_fds[0]);
                pah_kill_and_reap(child);
                return PAH_COMMAND_ERROR;
            }
        }

        if (!pah_monotonic_millis(&now)) {
            (void)close(pipe_fds[0]);
            pah_kill_and_reap(child);
            return PAH_COMMAND_ERROR;
        }
        if (now >= deadline || now + 1U < now) {
            (void)close(pipe_fds[0]);
            pah_kill_and_reap(child);
            return PAH_COMMAND_TIMEOUT;
        }

        poll_timeout = (int)(deadline - now);
        if (poll_timeout > 20) {
            poll_timeout = 20;
        }

        poll_fd.fd = pipe_fds[0];
        poll_fd.events = read_open ? POLLIN : 0;
        poll_fd.revents = 0;
        if (poll(read_open ? &poll_fd : NULL, read_open ? 1U : 0U, poll_timeout) < 0 &&
            errno != EINTR) {
            (void)close(pipe_fds[0]);
            pah_kill_and_reap(child);
            return PAH_COMMAND_ERROR;
        }
    }

    (void)close(pipe_fds[0]);
    *output_length = captured;
    if (WIFEXITED(child_status)) {
        *exit_code = WEXITSTATUS(child_status);
    } else if (WIFSIGNALED(child_status)) {
        *exit_code = 128 + WTERMSIG(child_status);
    } else {
        *exit_code = 125;
    }

    return PAH_COMMAND_OK;
}

static pah_result_t pah_map_command_result(int command_result)
{
    switch (command_result) {
    case PAH_COMMAND_TIMEOUT:
        return PAH_ERR_COMMAND_TIMEOUT;
    case PAH_COMMAND_OUTPUT_LIMIT:
        return PAH_ERR_OUTPUT_LIMIT;
    case PAH_COMMAND_ERROR:
        return PAH_ERR_SUBPROCESS_FAILURE;
    case PAH_COMMAND_OK:
    default:
        return PAH_OK;
    }
}

static int pah_state_allows_restart(const char *output, size_t output_length)
{
    static const char inactive_state[] = "loaded\ninactive\n";
    static const char failed_state[] = "loaded\nfailed\n";

    return (output_length == sizeof(inactive_state) - 1U &&
            memcmp(output, inactive_state, sizeof(inactive_state) - 1U) == 0) ||
           (output_length == sizeof(failed_state) - 1U &&
            memcmp(output, failed_state, sizeof(failed_state) - 1U) == 0);
}

static int pah_state_is_active(const char *output, size_t output_length)
{
    static const char active_state[] = "loaded\nactive\n";
    static const char activating_state[] = "loaded\nactivating\n";
    static const char deactivating_state[] = "loaded\ndeactivating\n";

    return (output_length == sizeof(active_state) - 1U &&
            memcmp(output, active_state, sizeof(active_state) - 1U) == 0) ||
           (output_length == sizeof(activating_state) - 1U &&
            memcmp(output, activating_state, sizeof(activating_state) - 1U) == 0) ||
           (output_length == sizeof(deactivating_state) - 1U &&
            memcmp(output, deactivating_state, sizeof(deactivating_state) - 1U) == 0);
}

pah_result_t pah_execute(
    const pah_request_t *request,
    pah_command_runner_fn runner,
    void *runner_context)
{
    char state_output[PAH_MAX_COMMAND_OUTPUT_BYTES];
    char restart_output[PAH_MAX_COMMAND_OUTPUT_BYTES];
    size_t state_output_length = 0U;
    size_t restart_output_length = 0U;
    int state_exit_code = 0;
    int restart_exit_code = 0;
    int command_result;
    pah_result_t validation_result;
    const char *state_argv[] = {
        pah_systemctl,
        "show",
        "--no-pager",
        "--plain",
        "--property=LoadState,ActiveState",
        "--value",
        NULL,
        NULL
    };
    const char *restart_argv[] = {pah_systemctl, "restart", NULL, NULL};

    validation_result = pah_validate_request(request);
    if (validation_result != PAH_OK) {
        return validation_result;
    }

    state_argv[6] = request->target_unit;
    restart_argv[2] = request->target_unit;
    if (runner == NULL) {
        runner = pah_direct_command_runner;
    }

    command_result = runner(state_argv, 7U, state_output, sizeof(state_output),
                            &state_output_length, PAH_STATE_TIMEOUT_MS,
                            &state_exit_code, runner_context);
    if (command_result != PAH_COMMAND_OK) {
        return pah_map_command_result(command_result);
    }
    if (state_output_length > sizeof(state_output)) {
        return PAH_ERR_OUTPUT_LIMIT;
    }
    if (state_exit_code != 0) {
        return PAH_ERR_SUBPROCESS_FAILURE;
    }
    if (pah_state_is_active(state_output, state_output_length)) {
        return PAH_ERR_UNIT_ACTIVE;
    }
    if (!pah_state_allows_restart(state_output, state_output_length)) {
        return PAH_ERR_UNIT_NOT_LOADED;
    }

    command_result = runner(restart_argv, 3U, restart_output, sizeof(restart_output),
                            &restart_output_length, PAH_RESTART_TIMEOUT_MS,
                            &restart_exit_code, runner_context);
    if (command_result != PAH_COMMAND_OK) {
        return pah_map_command_result(command_result);
    }
    if (restart_output_length > sizeof(restart_output)) {
        return PAH_ERR_OUTPUT_LIMIT;
    }
    if (restart_exit_code != 0) {
        return PAH_ERR_SUBPROCESS_FAILURE;
    }

    return PAH_OK;
}

const char *pah_result_name(pah_result_t result)
{
    switch (result) {
    case PAH_OK:
        return "ok";
    case PAH_ERR_MALFORMED:
        return "malformed";
    case PAH_ERR_MALFORMED_ENCODING:
        return "malformed_encoding";
    case PAH_ERR_OVERSIZED:
        return "oversized";
    case PAH_ERR_EXTRA_FIELDS:
        return "extra_fields";
    case PAH_ERR_UNSUPPORTED_PROTOCOL:
        return "unsupported_protocol";
    case PAH_ERR_UNKNOWN_PROFILE:
        return "unknown_profile";
    case PAH_ERR_UNSUPPORTED_PROFILE_VERSION:
        return "unsupported_profile_version";
    case PAH_ERR_UNKNOWN_ACTION:
        return "unknown_action";
    case PAH_ERR_INVALID_TARGET:
        return "invalid_target";
    case PAH_ERR_UNIT_NOT_LOADED:
        return "unit_not_loaded";
    case PAH_ERR_UNIT_ACTIVE:
        return "unit_active";
    case PAH_ERR_COMMAND_TIMEOUT:
        return "command_timeout";
    case PAH_ERR_SUBPROCESS_FAILURE:
        return "subprocess_failure";
    case PAH_ERR_OUTPUT_LIMIT:
        return "output_limit";
    case PAH_ERR_INTERNAL:
    default:
        return "internal";
    }
}

#ifndef PROFILE_ACTION_HELPER_NO_MAIN
static int pah_read_request(unsigned char *input, size_t *input_length)
{
    size_t length = 0U;
    uint64_t deadline;

    if (!pah_monotonic_millis(&deadline)) {
        return 0;
    }
    deadline += PAH_INPUT_TIMEOUT_MS;

    for (;;) {
        struct pollfd input_fd = {.fd = STDIN_FILENO, .events = POLLIN, .revents = 0};
        uint64_t now;
        int timeout;
        int poll_result;
        ssize_t count;

        if (!pah_monotonic_millis(&now) || now >= deadline) {
            return 0;
        }
        timeout = (int)(deadline - now);
        poll_result = poll(&input_fd, 1U, timeout);
        if (poll_result < 0 && errno == EINTR) {
            continue;
        }
        if (poll_result < 0) {
            return 0;
        }
        if (poll_result == 0) {
            return 0;
        }

        count = read(STDIN_FILENO, input + length, PAH_MAX_REQUEST_BYTES + 1U - length);
        if (count < 0 && errno == EINTR) {
            continue;
        }
        if (count < 0) {
            return 0;
        }
        if (count == 0) {
            *input_length = length;
            return 1;
        }

        length += (size_t)count;
        if (length > PAH_MAX_REQUEST_BYTES) {
            *input_length = length;
            return 1;
        }
    }
}

static int pah_exit_code(pah_result_t result)
{
    switch (result) {
    case PAH_OK:
        return 0;
    case PAH_ERR_COMMAND_TIMEOUT:
        return 5;
    case PAH_ERR_SUBPROCESS_FAILURE:
    case PAH_ERR_OUTPUT_LIMIT:
        return 6;
    case PAH_ERR_UNIT_ACTIVE:
    case PAH_ERR_UNIT_NOT_LOADED:
        return 4;
    case PAH_ERR_INTERNAL:
        return 70;
    default:
        return 2;
    }
}

int main(int argc, char **argv)
{
    unsigned char input[PAH_MAX_REQUEST_BYTES + 1U];
    size_t input_length = 0U;
    pah_request_t request;
    pah_result_t result;
    (void)argv;

    if (argc != 1) {
        return pah_exit_code(PAH_ERR_MALFORMED);
    }
    if (!pah_read_request(input, &input_length)) {
        return pah_exit_code(PAH_ERR_MALFORMED);
    }

    result = pah_parse_request(input, input_length, &request);
    if (result == PAH_OK) {
        result = pah_validate_request(&request);
    }
    if (result == PAH_OK) {
        result = pah_execute(&request, NULL, NULL);
    }

    if (result == PAH_OK) {
        (void)fputs("ok\n", stdout);
    } else {
        (void)fprintf(stderr, "profile-action-helper: %s\n", pah_result_name(result));
    }
    return pah_exit_code(result);
}
#endif
