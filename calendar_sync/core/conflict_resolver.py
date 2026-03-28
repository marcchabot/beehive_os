"""
core/conflict_resolver.py — Event conflict resolution.

v1: Remote wins on id collision (last-write-wins).
v2 will implement 3-way merge using sync_state.json as the base snapshot.
"""
from __future__ import annotations


def resolve(local: list[dict], remote: list[dict]) -> list[dict]:
    """Merge local and remote event lists.

    Strategy (v1): remote supersedes local on id collision.
    Both lists must contain dicts with at least "id" and "timestamp" keys.
    Returns a chronologically sorted, deduplicated list.
    """
    merged: dict[str, dict] = {ev["id"]: ev for ev in local}
    merged.update({ev["id"]: ev for ev in remote})  # remote wins
    return sorted(merged.values(), key=lambda e: e["timestamp"])
