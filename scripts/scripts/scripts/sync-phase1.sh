#!/usr/bin/env bash
set -euo pipefail

# Apply Phase 1 theme (maroon/gold/cream) on top of GitHub main, then push
# to trigger Build APK. Run inside your GitHub Codespace:
#   bash scripts/sync-phase1.sh

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [[ ! -f scripts/phase1-theme.patch ]]; then
  echo "Missing scripts/phase1-theme.patch — pull latest from this branch first."
  exit 1
fi

echo "==> Applying Phase 1 theme patch..."
git apply --check scripts/phase1-theme.patch
git apply scripts/phase1-theme.patch

echo "==> Committing..."
git add lib/theme lib/widgets/rishta_book_logo.dart lib/screens/auth/auth_landing_screen.dart \
  lib/screens/home/home_page.dart lib/utils/portrait.dart lib/widgets/rb_avatar.dart \
  pubspec.yaml android/app/src/main/res/values/colors.xml web/manifest.json \
  .github/workflows/build-apk.yml scripts/phase1-theme.patch scripts/sync-phase1.sh 2>/dev/null || true
git add -u
git commit -m "Phase 1: maroon/gold theme, Playfair+Inter fonts, matrimonial logo (v1.2.2+106)

Build 108 reused old GitHub code (ae8ffb5 orchid theme). This commit
applies the matrimonial redesign and bumps version so APK builds are
easy to verify."

echo "==> Pushing to GitHub (auto-starts Build APK)..."
git push origin main

echo
echo "Done. New build will include maroon theme + logo."
echo "Watch: https://github.com/rekhavijay9890-ops/RishtaBook-v2/actions"
echo "Download: https://github.com/rekhavijay9890-ops/RishtaBook-v2/releases/latest"
echo "Verify in app: version should show 1.2.2 (106)"
