#!/bin/bash
set -e
echo "🔍 Type checking..."
npx tsc --noEmit
echo "✅ Type check passed"