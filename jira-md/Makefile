# Загружает переменные из .env, если он есть (JIRA_URL, JIRA_EMAIL, JIRA_TOKEN, JIRA_PROJECT)
ifneq (,$(wildcard .env))
include .env
export
endif

.PHONY: jira_dry jira_tasks backlog

## Проверить epic-task.md: показать, что будет создано (без обращения к Jira)
jira_dry:
	python3 jira_sync.py --dry-run

## Создать задачи в Jira и заархивировать epic-task.md в backlog/
jira_tasks:
	python3 jira_sync.py

## Показать журнал миграций
backlog:
	@ls -1 backlog/ 2>/dev/null || echo "backlog/ пуста"
