# debian_init

Скрипт приводит Debian или Ubuntu к единому виду: обновляет пакеты,
раскладывает bash-окружение и tmux, настраивает имя компьютера, при
необходимости — LVM и `zabbix-agent2`.

Поддерживаются Debian 12/13 и Ubuntu 24.04+. ALT Linux и RHEL не
поддерживаются — см. раздел «Ограничения».

Точка входа — `install.sh`; остальные файлы подключаются им.

## Что делает

- проверяет ОС и источники APT, отключает `cdrom:`, для Debian при необходимости
  создаёт `debian.sources`;
- обновляет систему и устанавливает пакеты из `packages/*.list`;
- раскладывает `/etc/bash/*`, `.bashrc` и `.tmux.conf` в `/root`, `/etc/skel`
  и, по запросу, в домашние каталоги пользователей;
- меняет имя компьютера, `machine-id` и SSH host keys (для клонов ВМ);
- переименовывает корневую VG LVM в `<hostname>-vg`;
- настраивает `zabbix-agent2`;
- по запросу ставит дополнительные компоненты: git, fzf, Python, Node.js,
  Docker, zsh.

## Требования

- Debian 12/13 или Ubuntu 24.04+;
- root или пользователь с `sudo`;
- сеть и рабочие источники APT;
- `systemd` — для `hostnamectl`, пересоздания SSH-ключей и управления
  сервисами (в chroot часть шагов работает в ограниченном режиме);
- `lvm2` и корень на LVM — для шага `lvm`;
- пакет `zabbix-agent2` в репозиториях — для шага `zabbix`.

## Быстрый старт

После `netinst` в системе может не быть `curl`, `git` и `sudo`. Минимальный
bootstrap от root:

```bash
su -
apt-get update && apt-get install -y git ca-certificates
git clone https://github.com/Van-Hoffen/debian_init
cd debian_init
./install.sh
```

Без git (`wget` в Debian есть по умолчанию):

```bash
wget -qO- https://github.com/Van-Hoffen/debian_init/archive/refs/heads/main.tar.gz | tar xz
cd debian_init-main
./install.sh
```

Если запустить скрипт от обычного пользователя и в системе есть `sudo`, он
перезапустится через `sudo`. Без `sudo` скрипт попросит выполнить `su -`.

Перед реальными изменениями полезно посмотреть план:

```bash
./install.sh --mode existing --dry-run
```

## Режимы

| Режим | Сценарий | Имя компьютера | VG LVM | machine-id / SSH host keys | Dotfiles существующим пользователям |
|---|---|---|---|---|---|
| `fresh` | Свежая установка | только если задан `--hostname` | только если задан `--rename-vg` | нет | нет |
| `template` | Клон из шаблона ВМ | спрашивает | спрашивает | спрашивает, по умолчанию да | нет |
| `existing` | Уже используемая машина | спрашивает | спрашивает | нет | да |

Без `--mode` в терминале показывается меню. В неинтерактивном режиме
(например, `-y` без `--mode`) режим нужно указать явно.

Во всех режимах выполняются общие шаги: подготовка источников APT,
обновление, установка пакетов, файлы `/etc/bash`, dotfiles для `/root` и
`/etc/skel`. Режим влияет на вопросы об имени, VG и `machine-id`, на раздачу
dotfiles существующим пользователям и на `autoremove` в шаге `upgrade`
(в `existing` он не запускается).

С `-y` вопросы получают значения по умолчанию:

- имя компьютера и VG **не меняются** — нужны `--hostname` и `--rename-vg`
  (или `--vg-name`);
- в режиме `template` `machine-id` и SSH host keys **пересоздаются** (SSH —
  если установлен `openssh-server`);
- в режиме `existing` dotfiles существующим пользователям **обновляются**.

## Параметры

Полный список с описанием — `./install.sh --help`. Основные параметры:

| Параметр | Назначение |
|---|---|
| `--mode fresh\|template\|existing` | Сценарий запуска |
| `--hostname NAME` | Новое имя компьютера |
| `--rename-vg` / `--no-rename-vg` | Переименовать корневую VG или не трогать |
| `--vg-name NAME` | Явное имя VG вместо `<hostname>-vg` |
| `--reset-identity` / `--no-reset-identity` | Пересоздать `machine-id` и SSH host keys |
| `--all-users` / `--no-all-users` | Раздавать ли dotfiles существующим пользователям |
| `--platform auto\|hw\|vm\|kvm\|microsoft\|vmware` | Тип машины для выбора списка пакетов |
| `--allow-remove` | Разрешить apt удалять уже установленные пакеты |
| `--zabbix-server ADDR` | Настроить `zabbix-agent2` на этот сервер |
| `--extras LIST\|all` | Дополнительные компоненты |
| `--extras-user USER` | Для какого пользователя ставить extras |
| `--git-name NAME`, `--git-email EMAIL` | Данные для компонента `gitconfig` |
| `--only STEP[,STEP]` | Выполнить только указанные шаги |
| `--skip STEP[,STEP]` | Пропустить указанные шаги |
| `--list-steps` | Показать шаги и выйти |
| `-y`, `--yes` | Без вопросов, значения по умолчанию |
| `-n`, `--dry-run` | Показать действия, ничего не меняя |

`preflight` выполняется всегда, в том числе с `--only` и `--skip`. Если указать
`--only` без `--mode`, выполняются только выбранные шаги.

## Примеры

```bash
./install.sh --mode fresh --hostname srv-web01 --rename-vg -y
./install.sh --mode template
./install.sh --mode existing --dry-run
./install.sh --only hostname,lvm --hostname srv-db02 --rename-vg
./install.sh --only extras --extras docker,node --extras-user ivan
./install.sh --skip upgrade --mode existing
./install.sh --list-steps
./install.sh --help
```

## Документация

- [Использование: шаги, пакеты, диагностика, extras, LVM](docs/usage.md).
- [Разработка и проверка](docs/usage.md#разработка-и-проверка).
- [Шпаргалка по tmux](docs/readme_tmux.md).
- `./install.sh --help` — все параметры.
- `./install.sh --list-steps` — список шагов.

## Структура

```text
install.sh             оркестратор: параметры, режимы, порядок шагов
lib/common.sh          общие функции: лог, dry-run, вопросы, apt, бэкапы, копирование
modules/10-base.sh     preflight, upgrade, packages
modules/20-files.sh    system-files, dotfiles, users
modules/30-identity.sh hostname, identity, lvm
modules/40-optional.sh zabbix, extras
packages/*.list        списки пакетов
files/etc/bash/        системные файлы bash → /etc/bash
files/home/            .bashrc, .tmux.conf → домашние каталоги
docs/usage.md          шаги, пакеты, диагностика, extras, LVM
docs/readme_tmux.md    документация по tmux
```

## Ограничения

- Проверено в chroot Debian 13 (debootstrap) без systemd и без LVM.
  Переименование VG на реальной LVM и welcome-экран под systemd нужно
  проверить на тестовой ВМ.
- Рассчитано на Debian 12/13 и Ubuntu 24.04+. RPM-дистрибутивы (ALT Linux,
  RHEL) не поддерживаются: шаги `packages` и `upgrade` используют apt/dpkg,
  без них шаг пакетов пропускается с предупреждением.
- На Ubuntu набор пакетов отличается от Debian: отсутствующие в репозиториях
  пакеты пропускаются с предупреждением (см. `--allow-remove` и
  [диагностику](docs/usage.md#диагностика-и-устранение-проблем)).
- Скрипт не настраивает firewall, не создаёт пользователей и не управляет
  SSH-конфигом, кроме пересоздания host keys.

## Лицензия

GNU General Public License v3.0. См. [LICENSE](LICENSE).
