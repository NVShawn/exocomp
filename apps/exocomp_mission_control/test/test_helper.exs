# SPDX-FileCopyrightText: 2026 Exocomp contributors
# SPDX-License-Identifier: Apache-2.0
ExUnit.start()

# Ensure all apps are started for testing
Application.ensure_all_started(:exocomp_mission_control)

# Seed random number generator
:random.seed(:os.timestamp())
