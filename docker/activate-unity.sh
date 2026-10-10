#!/bin/bash
set -euo pipefail

# Unity Personal license activation for game-ci Docker images.
# Run once to generate a .ulf license file, then mount it for all future runs.
#
# Usage:
#   ./docker/activate-unity.sh                    Step 1: generate .alf request
#   ./docker/activate-unity.sh <path-to.ulf>      Step 2: activate with .ulf file

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BENCH_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
UNITY_VERSION="${UNITY_VERSION:-2022.3.33f1}"
IMAGE="unityci/editor:${UNITY_VERSION}-linux-il2cpp-3"
LICENSE_DIR="${BENCH_ROOT}/docker/license"

mkdir -p "$LICENSE_DIR"

if [[ $# -eq 0 ]]; then
    echo "============================================================"
    echo "  Unity Personal License Activation — Step 1"
    echo "============================================================"
    echo ""
    echo "Generating license request file (.alf)..."
    echo ""

    docker run --rm --platform linux/amd64 \
        -v "${LICENSE_DIR}:/license" \
        "$IMAGE" \
        bash -c '
            unity-editor -batchmode -nographics -createManualActivationFile -logFile /dev/stdout 2>&1 || true
            find /root -name "*.alf" -exec cp {} /license/ \; 2>/dev/null
            find /tmp -name "*.alf" -exec cp {} /license/ \; 2>/dev/null
            find / -maxdepth 3 -name "*.alf" -exec cp {} /license/ \; 2>/dev/null || true
        '

    ALF_FILE=$(find "$LICENSE_DIR" -name "*.alf" -print -quit 2>/dev/null)
    if [[ -z "$ALF_FILE" ]]; then
        echo "ERROR: No .alf file generated. Check Docker output above."
        exit 1
    fi

    echo ""
    echo "============================================================"
    echo "  .alf file generated: ${ALF_FILE}"
    echo ""
    echo "  Now:"
    echo "  1. Go to https://license.unity3d.com/manual"
    echo "  2. Upload: ${ALF_FILE}"
    echo "  3. Select 'Unity Personal' and download the .ulf file"
    echo "  4. Run: ./docker/activate-unity.sh <path-to-downloaded.ulf>"
    echo "============================================================"

elif [[ -f "$1" ]]; then
    ULF_FILE="$1"
    echo "============================================================"
    echo "  Unity Personal License Activation — Step 2"
    echo "============================================================"
    echo ""
    echo "Activating with: ${ULF_FILE}"

    cp "$ULF_FILE" "${LICENSE_DIR}/Unity_v${UNITY_VERSION}.ulf"

    docker run --rm --platform linux/amd64 \
        -v "${LICENSE_DIR}/Unity_v${UNITY_VERSION}.ulf:/root/.local/share/unity3d/Unity/Unity_lic.ulf:ro" \
        "$IMAGE" \
        bash -c '
            unity-editor -batchmode -nographics -quit -logFile /dev/stdout 2>&1 || true
            echo ""
            if unity-editor -batchmode -nographics -quit -logFile /dev/stdout 2>&1 | grep -q "License activated"; then
                echo "License activation: SUCCESS"
            else
                echo "License loaded (verify with a build test)"
            fi
        '

    echo ""
    echo "============================================================"
    echo "  License stored: ${LICENSE_DIR}/Unity_v${UNITY_VERSION}.ulf"
    echo ""
    echo "  To run benchmarks with Unity verification:"
    echo "  ./scripts/run-all.sh --agent <cmd> --label <name> --docker --docker-image ugb-unity"
    echo "============================================================"
else
    echo "ERROR: File not found: $1"
    echo "Usage:"
    echo "  ./docker/activate-unity.sh                 Generate .alf request"
    echo "  ./docker/activate-unity.sh <path-to.ulf>   Activate with .ulf file"
    exit 1
fi
