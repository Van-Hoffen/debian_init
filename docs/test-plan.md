# План тестирования debian_init

Документ описывает, **что** и **как** проверяется. Машиночитаемый список
утверждений — `tests/manifest.yaml`; запуск — `tests/run.sh`.

## 1. Цель

Проверить, что `install.sh` делает то, что заявлено в README, `--help` и
`docs/usage.md`, не ломает уже используемую систему и остаётся идемпотентным.

## 2. Уровни и среда

| Уровень | Что проверяет | Среда | Когда |
|---|---|---|---|
| `static` | синтаксис, shellcheck, снапшоты `--help`/`--list-steps`, ссылки в docs | хост + Docker | каждый коммит |
| `unit` | функции `lib/common.sh` с моками apt/dpkg | хост | каждый коммит |
| `cli` | аргументы, коды возврата, сообщения, lock | Docker (Debian 13, root) | каждый PR |
| `integration` | реальные шаги в одноразовом контейнере: файлы, users, hostname, identity, zabbix, extras, dry-run | Docker (Debian 13 / systemd-образ) | каждый PR |
| `slow` | полный `install.sh --mode fresh -y` с реальными пакетами | Docker + сеть | nightly/вручную |
| `vm` | LVM `vgrename`, initramfs/GRUB, перезагрузка, реальный `hostnamectl` | QEMU/KVM | nightly/релиз |

`static`, `unit`, `cli`, `integration` — обязательные. `slow` и `vm` — отдельно:
они дорогие и/или требуют инфраструктуры.

## 3. Изоляция

- Каждый тест получает свежий контейнер (`--rm`), репозиторий монтируется
  только на чтение (`-v "$ROOT:/src:ro"`).
- `--network none` для тестов, которым сеть не нужна.
- Для systemd-шагов — привилегированный контейнер с образом
  `debian-init-test:systemd`; перед шагом `hostname` снимаются bind-mount'ы
  `/etc/hostname` и `/etc/hosts`, иначе `hostnamectl`/`sed -i` не работают.
- VM-тесты — только на одноразовой VM со снапшотом, без доступа к хосту.
- Тесты не пишут в домашний каталог пользователя, `/etc` хоста и репозиторий;
  артефакты — в контейнере или `tests/.artifacts/` (в `.gitignore`).
- Секреты и реальные данные не используются.

## 4. Матрица покрытия

Идентификаторы совпадают с `tests/manifest.yaml`.

| ID | Область | Проверка | Уровень | Тест |
|---|---|---|---|---|
| STAT-001 | статика | все bash-файлы проходят `bash -n` | static | `tests/static/test_syntax.sh` |
| STAT-002 | статика | shellcheck без замечаний | static | `tests/static/test_shellcheck.sh` |
| STAT-003 | контракт | `--help` и `--list-steps` совпадают со снапшотами | static | `tests/static/test_snapshots.sh` |
| STAT-004 | docs | относительные ссылки в Markdown существуют | static | `tests/static/test_docs_links.sh` |
| UNIT-001 | common | `valid_hostname`, `read_list`, `sed_escape_*` | unit | `tests/unit/test_common.sh` |
| UNIT-002 | apt | `ensure_pkgs`: обычная установка, `--no-remove` | unit | `tests/unit/test_common.sh` |
| UNIT-003 | apt | `ensure_pkgs`: удаление заблокировано, fallback по одному, `dpkg --configure -a` | unit | `tests/unit/test_common.sh` |
| UNIT-004 | apt | `ensure_pkgs`: отсутствующий пакет, `--allow-remove` | unit | `tests/unit/test_common.sh` |
| UNIT-005 | run | `run`: dry-run не выполняет команду, ошибка возвращается | unit | `tests/unit/test_common.sh` |
| CLI-001 | CLI | `--help`, `--list-steps`, обязательные флаги в выводе | cli | `tests/cli/test_cli.sh` |
| CLI-002 | CLI | неизвестный флаг/режим/шаг, нехватка аргумента, недопустимый hostname | cli | `tests/cli/test_cli.sh` |
| CLI-003 | lock | второй экземпляр не запускается | cli | `tests/cli/test_lock.sh` |
| INT-001 | preflight | определение ОС/платформы, отключение `cdrom:`, создание `debian.sources` | integration | `tests/integration/test_preflight.sh` |
| INT-002 | upgrade | `existing` не делает `autoremove`; `fresh` делает; флаг перезагрузки | integration | `tests/integration/test_upgrade.sh` |
| INT-003 | файлы | `/etc/bash`, `/root`, `/etc/skel`, `.server_info` keep, бэкапы, symlink | integration | `tests/integration/test_files.sh` |
| INT-004 | users | выбор пользователей по UID/shell/home, владелец, идемпотентность | integration | `tests/integration/test_users.sh` |
| INT-005 | hostname | `/etc/hostname`, `127.0.1.1`, `/etc/mailname`, повторный запуск | integration | `tests/integration/test_hostname.sh` |
| INT-006 | hostname | недопустимое имя отклоняется | integration | `tests/integration/test_hostname.sh` |
| INT-007 | identity | новый `machine-id`, SSH host keys | integration | `tests/integration/test_identity.sh` |
| INT-008 | zabbix | замена `Server`/`ServerActive`/`Hostname`, отсутствие пакета | integration | `tests/integration/test_zabbix.sh` |
| INT-009 | lvm | без `lvm2` шаг пропускается | integration | `tests/integration/test_lvm.sh` |
| INT-010 | extras | `dirs`, `sshperms`, `append_local_once` без дублей | integration | `tests/integration/test_extras.sh` |
| INT-011 | dry-run | полный `--mode fresh --dry-run` не меняет систему | integration | `tests/integration/test_dry_run.sh` |
| INT-012 | файлы | `install_system_file`: идемпотентность, бэкап, `keep`, dry-run | integration | `tests/integration/test_files.sh` |
| INT-013 | режимы | `fresh`/`template`/`existing`, `--platform`, `--only`, `--skip` | integration | `tests/integration/test_modes.sh` |
| SLOW-001 | полный прогон | `--mode fresh -y` ставит пакеты и раскладывает файлы | slow | `tests/slow/test_full_install.sh` |
| VM-001 | hostname | реальный `hostnamectl` на systemd | vm | planned |
| VM-002 | lvm | `vgrename` корневой VG, fstab/crypttab, initramfs/GRUB | vm | planned |
| VM-003 | reboot | система загружается после переименования VG | vm | planned |
| VM-004 | identity | SSH host keys после перезагрузки | vm | planned |

## 5. Правила тестов

- Неинтерактивность: `-y`, `--dry-run`, `DEBIAN_FRONTEND=noninteractive`.
- Детерминизм: фиксированные имена, никакой зависимости от текущего времени,
  сети и порядка тестов.
- Каждый тест сам создаёт данные и убирает за собой.
- Один тест — одна причина падения; сообщение содержит ожидаемое и полученное.
- Не ослаблять тест, чтобы он прошёл; при изменении поведения обновлять
  `docs/test-plan.md` и `tests/manifest.yaml`.
- Новый флаг/шаг/режим без теста — ошибка покрытия.

## 6. Запуск

```bash
tests/run.sh                 # static + unit + cli + integration
tests/run.sh --tier unit     # только unit
tests/run.sh --tier slow     # полный прогон, нужна сеть
tests/run.sh --list          # список тестов
tests/run.sh --filter files  # по подстроке в пути
tests/run.sh --update-snapshots
```

Требования: bash, Docker; для `slow` — сеть; для `vm` — QEMU/KVM.

## 7. Критерии приёмки

- Все обязательные уровни зелёные.
- Нет пропущенных обязательных тестов; пропуск допустим только для `slow`/`vm`
  и явно указан в отчёте.
- Нет изменений на хосте после прогона.
- Для каждого `claim` из manifest есть тест; для каждого теста — проверяемое
  утверждение.
- Отчёт содержит команды, коды возврата и ключевой вывод.

## 8. Ограничения Phase 1

- LVM/GRUB/перезагрузка проверяются только в VM (пока `planned`).
- Docker-контейнер не является полноценной VM: `hostnamectl` требует снятия
  bind-mount'ов, LVM-корень и загрузка не проверяются.
- `slow` зависит от сети и зеркал; при недоступности пакетов возможны
  предупреждения (это тоже проверяется).
- Проверка env-переменных в `docs_sync` для shell-проектов может давать
  ложные срабатывания; в тестах она не используется.
