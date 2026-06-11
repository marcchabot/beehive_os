#!/usr/bin/env python3
"""
audit-static.py — Scan préventif des anti-patterns QML connus dans Bee-Hive OS.

Détecte :
- anchors.fill: parent sans anchors.margins
- Rectangle sans clip:true (risque débordement)
- Text sans elide ni wrapMode
- ListView/GridView/Flickable sans ScrollBar
- Couleurs hex hardcodées (à migrer vers theme)

Usage :
    python3 qa/audit-static.py                  # scan complet
    python3 qa/audit-static.py modules/MayaDash.qml  # un seul fichier
    python3 qa/audit-static.py --top 5           # top 5 pires offenders
    python3 qa/audit-static.py --json            # sortie JSON

Retourne exit code 0 si OK, 1 si bugs détectés.
"""
import re
import sys
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MODULES_DIR = REPO_ROOT / "modules"


def analyze_file(qml_path: Path) -> dict:
    """Analyse un fichier .qml et retourne un dict d'issues."""
    content = qml_path.read_text(encoding="utf-8", errors="ignore")
    issues = []

    # 1. anchors.fill sans margins
    fill = len(re.findall(r"anchors\.fill:\s*parent", content))
    margins = len(re.findall(r"anchors\.margins", content))
    if fill > margins + 2:
        issues.append({
            "pattern": "anchors.fill_sans_margins",
            "count": fill - margins,
            "severity": "minor",
            "msg": "{0} anchors.fill mais seulement {1} anchors.margins".format(fill, margins),
        })

    # 2. Rectangle sans clip
    rect = len(re.findall(r"Rectangle\s*\{", content))
    clip = len(re.findall(r"clip:\s*true", content))
    if rect > 5 and clip < rect / 4:
        issues.append({
            "pattern": "rectangle_sans_clip",
            "count": rect,
            "severity": "major",
            "msg": "{0} Rectangle, seulement {1} avec clip:true".format(rect, clip),
        })

    # 3. Text sans elide/wrapMode
    text = len(re.findall(r"\bText\s*\{", content))
    elide = len(re.findall(r"\belide:", content))
    wrap = len(re.findall(r"wrapMode:", content))
    if text > 3 and elide == 0 and wrap == 0:
        issues.append({
            "pattern": "text_sans_elide_wrap",
            "count": text,
            "severity": "minor",
            "msg": "{0} Text, aucun elide ni wrapMode".format(text),
        })

    # 4. ListView sans ScrollBar
    listview = len(re.findall(r"\bListView\s*\{|\bGridView\s*\{|\bFlickable\s*\{", content))
    scrollbar = len(re.findall(r"\bScrollBar\s*\{", content))
    if listview > 0 and scrollbar == 0:
        issues.append({
            "pattern": "listview_sans_scrollbar",
            "count": listview,
            "severity": "major",
            "msg": "{0} ListView/GridView sans ScrollBar visible".format(listview),
        })

    # 5. Couleurs hex hardcodées
    hex_colors = re.findall(r"#[0-9A-Fa-f]{6,8}", content)
    if len(hex_colors) > 20:
        issues.append({
            "pattern": "hex_colors_hardcoded",
            "count": len(hex_colors),
            "severity": "minor",
            "msg": "{0} couleurs hex hardcodees".format(len(hex_colors)),
        })

    return {
        "file": str(qml_path.relative_to(REPO_ROOT)),
        "size": qml_path.stat().st_size,
        "issues": issues,
    }


def main():
    args = sys.argv[1:]
    json_mode = "--json" in args
    top_mode = None
    for i, a in enumerate(args):
        if a == "--top" and i + 1 < len(args):
            try:
                top_mode = int(args[i + 1])
            except ValueError:
                pass

    # Files to scan
    targets = []
    for a in args:
        if a.endswith(".qml") and not a.startswith("-"):
            p = Path(a)
            if not p.is_absolute():
                p = REPO_ROOT / p
            if p.exists():
                targets.append(p)
    if not targets:
        targets = sorted(MODULES_DIR.glob("*.qml"))

    results = [analyze_file(p) for p in targets]
    results = [r for r in results if r["issues"]]

    # Severity score for ranking
    severity_score = {"critical": 4, "major": 3, "minor": 2, "nit": 1}
    for r in results:
        r["score"] = sum(
            severity_score.get(i["severity"], 0) * i["count"]
            for i in r["issues"]
        )
    results.sort(key=lambda r: -r["score"])

    if top_mode:
        results = results[:top_mode]

    if json_mode:
        print(json.dumps(results, indent=2, ensure_ascii=False))
    else:
        total_issues = sum(len(r["issues"]) for r in results)
        print("=== {0} fichiers avec issues, {1} issues au total ===".format(len(results), total_issues))
        print()
        for r in results:
            print("=== {0}  ({1:,} bytes, score {2})".format(r["file"], r["size"], r["score"]))
            for i in r["issues"]:
                sev = {"critical": "[CRIT]", "major": "[MAJ ]", "minor": "[MIN ]", "nit": "[NIT ]"}.get(i["severity"], "[????]")
                print("   {0} {1}: {2}".format(sev, i["pattern"], i["msg"]))
            print()

    return 1 if results else 0


if __name__ == "__main__":
    sys.exit(main())
