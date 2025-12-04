# Bot CLI Task Manager

Простой консольный менеджер задач на Elixir.  
Поддерживает добавление, удаление, поиск, фильтрацию, редактирование и экспорт задач.

## Возможности
- Добавление задач с полями:
  - **title**
  - **deadline**
  - **category**
  - **priority**
  - **recurring**
- Список всех задач: `task list`
- Ближайшие дедлайны: `task upcoming`
- Поиск по тексту: `task search TEXT`
- Фильтрация по категории: `task filter CATEGORY`
- Редактирование: `task edit ID ...`
- Удаление: `task delete ID`
- Экспорт в `tasks.json` и `tasks.txt`: `task export`
