#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_dir="$(cd "${script_dir}/.." && pwd)"
target_dir="${GPIG_TEAM_A_DIR:-${workspace_dir}/gpig-team-a}"
repo_url="${GPIG_TEAM_A_REPO:-https://github.com/rs-sandhu/gpig-team-a.git}"
repo_ref="${GPIG_TEAM_A_REF:-main}"

if [ -d "${target_dir}/.git" ]; then
  echo "[gpig] gpig-team-a already exists at ${target_dir}; leaving it untouched."
  exit 0
fi

if [ -e "${target_dir}" ] && [ "$(find "${target_dir}" -mindepth 1 -maxdepth 1 | head -n 1)" ]; then
  echo "[gpig] ${target_dir} exists and is not an empty git checkout; skipping clone."
  exit 0
fi

echo "[gpig] Cloning ${repo_url} (${repo_ref}) into ${target_dir}..."
if git clone --branch "${repo_ref}" "${repo_url}" "${target_dir}"; then
  exit 0
fi

echo "[gpig] Branch ${repo_ref} was not available; cloning the repository default branch."
git clone "${repo_url}" "${target_dir}"
if git -C "${target_dir}" rev-parse --verify --quiet "origin/${repo_ref}" >/dev/null; then
  git -C "${target_dir}" checkout "${repo_ref}"
fi
