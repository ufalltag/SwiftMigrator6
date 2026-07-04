#!/usr/bin/env python3
"""
jira_sync.py — создаёт задачи в Jira из epic-task.md (формат: PROTOCOL.md)
и архивирует выгруженное в backlog/ как миграцию.

Возможности:
  - markdown в описаниях конвертируется в Jira wiki markup
  - общий DoD из dod.md дописывается к каждой задаче
  - связи задач через метаполя `> after:` и `> blocks:`

Использование:
  python3 jira_sync.py --dry-run   # показать план, ничего не создавать
  python3 jira_sync.py             # создать задачи и заархивировать

Конфиг — переменные окружения (или .env через Makefile):
  JIRA_URL, JIRA_EMAIL, JIRA_TOKEN, JIRA_PROJECT
"""

from __future__ import annotations

import os
import re
import sys
import datetime
from dataclasses import dataclass, field
from pathlib import Path

WORK_FILE = Path(os.getenv("EPIC_TASK_FILE", "epic-task.md"))
BACKLOG_DIR = Path(os.getenv("BACKLOG_DIR", "backlog"))
DOD_FILE = Path(os.getenv("DOD_FILE", "dod.md"))

JIRA_URL = os.getenv("JIRA_URL", "").rstrip("/")
EMAIL = os.getenv("JIRA_EMAIL", "")
API_TOKEN = os.getenv("JIRA_TOKEN", "")
PROJECT_KEY = os.getenv("JIRA_PROJECT", "SWIFTMIG")

EPIC_TYPE = os.getenv("JIRA_EPIC_TYPE", "Epic")
DEFAULT_TASK_TYPE = os.getenv("JIRA_TASK_TYPE", "Task")

EMPTY_TEMPLATE = """--- <номер пункта плана> <короткий тезис>

<!--
Формат и шаблон описания задачи — PROTOCOL.md.
Секции задачи: Контекст / Что сделать / Технические заметки /
Критерии приёмки / Как проверить / Вне скоупа.
Метаполя: > estimate: / > labels: / > after: / > blocks:
Запуск: make jira_dry / make jira_tasks
-->
"""

RE_KEY = re.compile(r"^[A-Z][A-Z0-9_]*-\d+$")

# ─── Модель ──────────────────────────────────────────────────────────────────

@dataclass
class Task:
    title: str
    issue_type: str = DEFAULT_TASK_TYPE
    meta: dict = field(default_factory=dict)
    description: str = ""
    line: int = 0
    created_key: str | None = None

@dataclass
class Epic:
    title: str
    existing_key: str | None = None
    description: str = ""
    tasks: list[Task] = field(default_factory=list)
    line: int = 0
    created_key: str | None = None

@dataclass
class Header:
    plan_point: str
    thesis: str
    line: int = 0

RE_HEADER = re.compile(r"^---\s+(\d+[a-zа-я]?)\s+(.+?)\s*$")
RE_EPIC = re.compile(r"^#\s+(?:@([A-Z][A-Z0-9_]*-\d+)\s+)?(.+?)\s*$")
RE_TASK = re.compile(r"^##\s+(?:\[(\w+)\]\s+)?(.+?)\s*$")
RE_META = re.compile(r"^>\s*([\w-]+)\s*:\s*(.+?)\s*$")
RE_COMMENT = re.compile(r"<!--.*?-->", re.DOTALL)


# ─── Парсер ──────────────────────────────────────────────────────────────────

def parse(text: str) -> tuple[Header, list[Epic]]:
    text = RE_COMMENT.sub("", text)
    header: Header | None = None
    epics: list[Epic] = []
    current_epic: Epic | None = None
    current_task: Task | None = None
    desc_target = None
    meta_zone = False
    in_code_block = False

    for lineno, raw in enumerate(text.splitlines(), start=1):
        line = raw.rstrip()

        if header is None:
            if not line.strip():
                continue
            m = RE_HEADER.match(line)
            if not m:
                sys.exit(
                    f"Ошибка (строка {lineno}): первая строка должна быть шапкой\n"
                    f"  --- <номер пункта плана> <тезис>\n"
                    f"например: --- 5 Каркас проекта и базовая архитектура"
                )
            header = Header(plan_point=m.group(1), thesis=m.group(2), line=lineno)
            continue

        # внутри код-блоков заголовки/меты не распознаём
        if line.strip().startswith("```"):
            in_code_block = not in_code_block
            if desc_target is not None:
                desc_target.description += raw + "\n"
            meta_zone = False
            continue
        if in_code_block:
            if desc_target is not None:
                desc_target.description += raw + "\n"
            continue

        m = RE_TASK.match(line)  # ## раньше, чем #
        if m:
            if current_epic is None:
                sys.exit(f"Ошибка (строка {lineno}): задача «{m.group(2)}» вне эпика.")
            current_task = Task(
                title=m.group(2),
                issue_type=m.group(1) or DEFAULT_TASK_TYPE,
                line=lineno,
            )
            current_epic.tasks.append(current_task)
            desc_target = current_task
            meta_zone = True
            continue

        m = RE_EPIC.match(line)
        if m and not line.startswith("##"):
            current_epic = Epic(title=m.group(2), existing_key=m.group(1), line=lineno)
            epics.append(current_epic)
            current_task = None
            desc_target = current_epic
            meta_zone = False
            continue

        m = RE_META.match(line)
        if m and meta_zone and current_task is not None:
            current_task.meta[m.group(1).lower()] = m.group(2)
            continue

        if line.strip():
            meta_zone = False
        if desc_target is not None:
            desc_target.description += raw + "\n"

    if header is None:
        sys.exit(f"{WORK_FILE}: файл пуст или нет шапки «--- ...».")

    for e in epics:
        e.description = e.description.strip()
        for t in e.tasks:
            t.description = t.description.strip()
    return header, epics


def validate_links(epics: list[Epic]) -> None:
    """after/blocks должны указывать на ключ или на название задачи из файла."""
    titles = {t.title for e in epics for t in e.tasks}
    for e in epics:
        for t in e.tasks:
            for kind in ("after", "blocks"):
                ref = t.meta.get(kind)
                if ref and not RE_KEY.match(ref) and ref not in titles:
                    sys.exit(
                        f"Ошибка (задача «{t.title}», строка {t.line}): "
                        f"{kind}: «{ref}» — не ключ Jira и не название задачи из этого файла."
                    )


# ─── Markdown → Jira wiki markup ─────────────────────────────────────────────

def md_to_wiki(md: str) -> str:
    out: list[str] = []
    in_code = False
    for line in md.splitlines():
        stripped = line.strip()

        m = re.match(r"^```(\w+)?\s*$", stripped)
        if m:
            if not in_code:
                lang = m.group(1) or "text"
                out.append(f"{{code:{lang}}}")
                in_code = True
            else:
                out.append("{code}")
                in_code = False
            continue
        if in_code:
            out.append(line)
            continue

        # заголовки
        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if m:
            out.append(f"h{len(m.group(1))}. {m.group(2)}")
            continue

        # чекбоксы и списки
        line = re.sub(r"^(\s*)-\s+\[[ xX]\]\s+", r"\1* ☐ ", line)
        line = re.sub(r"^(\s*)-\s+", r"\1* ", line)

        # инлайновые элементы
        line = re.sub(r"\*\*(.+?)\*\*", r"*\1*", line)          # **bold** -> *bold*
        line = re.sub(r"(?<!\{)`([^`]+)`", r"{{\1}}", line)      # `code` -> {{code}}
        line = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", r"[\1|\2]", line)  # ссылки

        out.append(line)
    if in_code:
        out.append("{code}")
    return "\n".join(out)


# ─── Jira API ────────────────────────────────────────────────────────────────

def _session():
    import requests
    s = requests.Session()
    s.auth = (EMAIL, API_TOKEN)
    s.headers["Content-Type"] = "application/json"
    return s


def jira_create(session, fields: dict) -> str:
    resp = session.post(f"{JIRA_URL}/rest/api/2/issue", json={"fields": fields}, timeout=30)
    if resp.status_code not in (200, 201):
        sys.exit(f"Jira ответила {resp.status_code}: {resp.text}")
    return resp.json()["key"]


def jira_link(session, blocker_key: str, blocked_key: str) -> None:
    """blocker_key блокирует blocked_key."""
    resp = session.post(
        f"{JIRA_URL}/rest/api/2/issueLink",
        json={
            "type": {"name": "Blocks"},
            "inwardIssue": {"key": blocked_key},   # is blocked by
            "outwardIssue": {"key": blocker_key},  # blocks
        },
        timeout=30,
    )
    if resp.status_code not in (200, 201):
        print(f"  ⚠ не удалось создать связь {blocker_key} → {blocked_key}: "
              f"{resp.status_code} {resp.text[:200]}")


def create_all(epics: list[Epic], dod: str) -> None:
    session = _session()

    for e in epics:
        if e.existing_key:
            e.created_key = e.existing_key
            print(f"Эпик {e.existing_key} (существующий): «{e.title}»")
        else:
            e.created_key = jira_create(session, {
                "project": {"key": PROJECT_KEY},
                "issuetype": {"name": EPIC_TYPE},
                "summary": e.title,
                "description": md_to_wiki(e.description),
            })
            print(f"Эпик {e.created_key}: «{e.title}»")

        for t in e.tasks:
            description = t.description
            if dod:
                description = description.rstrip() + "\n\n" + dod
            fields = {
                "project": {"key": PROJECT_KEY},
                "issuetype": {"name": t.issue_type},
                "summary": t.title,
                "description": md_to_wiki(description),
                # Если Jira ругается на parent — старый company-managed проект:
                # замени на "customfield_10014": e.created_key (ID поля Epic Link)
                "parent": {"key": e.created_key},
            }
            if "labels" in t.meta:
                fields["labels"] = [x.strip() for x in t.meta["labels"].split(",")]
            t.created_key = jira_create(session, fields)
            est = f" ({t.meta['estimate']})" if "estimate" in t.meta else ""
            print(f"  └ {t.created_key}: «{t.title}»{est}")

    # связи after/blocks — после того как у всех есть ключи
    by_title = {t.title: t for e in epics for t in e.tasks}

    def resolve(ref: str) -> str | None:
        if RE_KEY.match(ref):
            return ref
        t = by_title.get(ref)
        return t.created_key if t else None

    for e in epics:
        for t in e.tasks:
            if "after" in t.meta:
                blocker = resolve(t.meta["after"])
                if blocker and t.created_key:
                    jira_link(session, blocker, t.created_key)
                    print(f"  ⛓ {blocker} блокирует {t.created_key}")
            if "blocks" in t.meta:
                blocked = resolve(t.meta["blocks"])
                if blocked and t.created_key:
                    jira_link(session, t.created_key, blocked)
                    print(f"  ⛓ {t.created_key} блокирует {blocked}")


# ─── Архивация в backlog/ ────────────────────────────────────────────────────

def slugify(s: str) -> str:
    s = re.sub(r"[^\w\s-]", "", s.lower()).strip()
    return re.sub(r"[\s_]+", "-", s)[:50] or "epic"


def archive(original: str, header: Header, epics: list[Epic]) -> Path:
    result = original

    for e in epics:
        if not e.existing_key and e.created_key:
            result = re.sub(
                rf"^(#\s+){re.escape(e.title)}\s*$",
                rf"\1[{e.created_key}] {e.title}",
                result, count=1, flags=re.MULTILINE,
            )
        for t in e.tasks:
            if t.created_key:
                result = re.sub(
                    rf"^(##\s+)(\[{re.escape(t.issue_type)}\]\s+)?{re.escape(t.title)}\s*$",
                    lambda m: f"{m.group(1)}[{t.created_key}] {t.title}",
                    result, count=1, flags=re.MULTILINE,
                )

    stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    epic_keys = ", ".join(e.created_key for e in epics if e.created_key)
    result = re.sub(
        r"^---\s+.+$",
        lambda m: f"{m.group(0)}\n<!-- migrated {stamp} | project {PROJECT_KEY} | epics: {epic_keys} -->",
        result, count=1, flags=re.MULTILINE,
    )

    BACKLOG_DIR.mkdir(exist_ok=True)
    base = f"{int(re.sub(r'[a-zа-я]', '', header.plan_point)):02d}_{slugify(header.thesis)}"
    path = BACKLOG_DIR / f"{base}.md"
    n = 2
    while path.exists():
        path = BACKLOG_DIR / f"{base}_{n}.md"
        n += 1
    path.write_text(result, encoding="utf-8")
    return path


# ─── main ────────────────────────────────────────────────────────────────────

def main() -> None:
    dry_run = "--dry-run" in sys.argv

    if not WORK_FILE.exists():
        sys.exit(f"Файл {WORK_FILE} не найден.")
    original = WORK_FILE.read_text(encoding="utf-8")
    header, epics = parse(original)

    if not epics:
        print(f"{WORK_FILE}: шапка есть, но эпиков нет — нечего создавать.")
        return

    validate_links(epics)
    dod = DOD_FILE.read_text(encoding="utf-8").strip() if DOD_FILE.exists() else ""

    total_tasks = sum(len(e.tasks) for e in epics)
    print(f"Пункт плана: {header.plan_point} — {header.thesis}")
    print(f"План: эпиков — {len(epics)}, задач — {total_tasks}"
          + (", DoD подключён" if dod else ", ⚠ dod.md не найден") + "\n")
    for e in epics:
        tag = f"@{e.existing_key} " if e.existing_key else ""
        print(f"# {tag}{e.title}")
        if not e.tasks:
            print("  ⚠ у эпика нет задач")
        for t in e.tasks:
            marks = [x for x in (
                t.issue_type if t.issue_type != DEFAULT_TASK_TYPE else None,
                t.meta.get("estimate"),
                f"after: {t.meta['after']}" if "after" in t.meta else None,
                f"blocks: {t.meta['blocks']}" if "blocks" in t.meta else None,
            ) if x]
            suffix = f"  [{', '.join(marks)}]" if marks else ""
            print(f"  ## {t.title}{suffix}")
            if not t.description:
                print("     ⚠ нет описания")
    print()

    if dry_run:
        print("--dry-run: ничего не создано.")
        return

    for var, name in [(JIRA_URL, "JIRA_URL"), (EMAIL, "JIRA_EMAIL"), (API_TOKEN, "JIRA_TOKEN")]:
        if not var:
            sys.exit(f"Не задана переменная окружения {name} (см. .env / Makefile).")

    create_all(epics, dod)

    path = archive(original, header, epics)
    WORK_FILE.write_text(EMPTY_TEMPLATE, encoding="utf-8")
    print(f"\nГотово. Архив миграции: {path}")
    print(f"{WORK_FILE} очищен и готов к следующему эпику.")


if __name__ == "__main__":
    main()
