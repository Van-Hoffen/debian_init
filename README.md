# debian_init

Инициализация установленной системы Debian (12 bookworm / 13 trixie): системные настройки bash, `.bashrc` / `.tmux.conf`, обновление, установка пакетов, переименование компьютера и группы томов LVM.

Точка входа одна — `install.sh`. Всё остальное подключается им.

## Быстрый старт

После `netinst` в системе может не быть `curl`, `git` и `sudo`. Минимальный bootstrap от root:

```bash
su -
apt-get update && apt-get install -y git ca-certificates
git clone https://github.com/Van-Hoffen/debian_init
cd debian_init
./install.sh
```

Без git (wget в Debian есть по умолчанию, priority standard):

```bash
wget -qO- https://github.com/Van-Hoffen/debian_init/archive/refs/heads/main.tar.gz | tar xz
cd debian_init-main
./install.sh
```

Скрипт должен запускаться от root. Если запущен от обычного пользователя и есть `sudo` — перезапустится через `sudo`, иначе подскажет `su -`.

## Режимы

| Режим | Сценарий | Имя компьютера | VG LVM | machine-id / SSH host keys | dotfiles существующим пользователям |
|---|---|---|---|---|---|
| `fresh` | Свежая установка | только если задан `--hostname` | только если задан `--rename-vg` | нет | нет (`/root` и `/etc/skel`) |
| `template` | Клон из шаблона ВМ | спрашивает | спрашивает | спрашивает (по умолчанию да) | нет |
| `existing` | Уже используемая машина | спрашивает | спрашивает | нет | да |

Без `--mode` в терминале показывается меню. Во всех режимах выполняются: подготовка источников APT, обновление, установка пакетов, файлы `/etc/bash`, dotfiles для `/root` и `/etc/skel`.

С `-y` вопросы получают значение по умолчанию: переименование компьютера и VG по умолчанию **нет** — для них нужно явно указать `--hostname` / `--rename-vg`.

## Примеры

```bash
./install.sh --mode fresh --hostname srv-web01 --rename-vg -y
./install.sh --mode template
./install.sh --mode existing --dry-run          # посмотреть, что будет сделано
./install.sh --only hostname,lvm --hostname srv-db02 --rename-vg
./install.sh --only extras --extras docker,node --extras-user ivan
./install.sh --list-steps
./install.sh --help                             # полный список параметров
```

## Шаги

| Шаг | Что делает |
|---|---|
| `preflight` | Проверки, отключение `cdrom:` в sources, создание `debian.sources` (deb822), если источников нет |
| `upgrade` | `apt-get update && full-upgrade` (неинтерактивно, `--force-confold`) |
| `packages` | `packages/base.list` + список по типу машины (`systemd-detect-virt` или `--platform`). Отсутствующие в текущем релизе пакеты пропускаются с предупреждением |
| `system-files` | `/etc/bash/*` (алиасы, welcome-экран, логотипы, список сервисов). `.server_info` не перезаписывается, если уже существует |
| `dotfiles` | `.bashrc`, `.tmux.conf` в `/root` и `/etc/skel` |
| `users` | `.bashrc`, `.tmux.conf` в домашние каталоги всех локальных пользователей (UID ≥ `UID_MIN`, через `getent passwd`) |
| `hostname` | `hostnamectl` (или `/etc/hostname`), строка `127.0.1.1` в `/etc/hosts`, `/etc/mailname` |
| `identity` | Новый `machine-id` и SSH host keys (для клонов) |
| `lvm` | Переименование VG корня в `<hostname>-vg` (стандарт установщика Debian) |
| `zabbix` | Конфиг `zabbix-agent2`, если задан `--zabbix-server` |
| `extras` | Необязательные компоненты, только по `--extras` |

`--only` и `--skip` принимают список шагов через запятую.

## Пакеты

Списки — `packages/*.list`, по одному пакету в строке, `#` — комментарий:

- `base.list` — для всех машин;
- `hw.list` — физическое железо;
- `vm-kvm.list`, `vm-qemu.list`, `vm-microsoft.list`, `vm-vmware.list` — гостевые агенты.

Учтены изменения Debian 13: `neofetch` и `software-properties-common` в trixie отсутствуют, `last` удалён из util-linux — вместо него `wtmpdb`.

## Пользовательские файлы

`.bashrc` и `.tmux.conf` копируются в каждый домашний каталог — пользователь может их править. Но при следующем запуске скрипта с шагом `users`/`dotfiles` они будут обновлены (старая версия сохраняется). Поэтому личные правки лучше держать в отдельных файлах, которые скрипт не трогает:

| Файл | Подключается из |
|---|---|
| `~/.bashrc.local` | `.bashrc` (в конце) |
| `~/.user_aliases` | `/etc/bash/.bash_aliases` (редактировать и применить: `ebal`) |
| `~/.tmux.local.conf` | `.tmux.conf` (в конце) |

Если файл в домашнем каталоге — символическая ссылка, он пропускается с предупреждением (защита от подмены ссылкой на `/etc/shadow` и т.п.). Запись выполняется от имени владельца каталога (`runuser`).

## Бэкапы и лог

- Пользовательские файлы: рядом, нумерованные копии `.bashrc.~1~`, `.bashrc.~2~`…; создаются только если содержимое реально меняется.
- Системные файлы (`/etc/hosts`, `/etc/fstab`, конфиги GRUB и т.д.): `/var/backups/debian_init/<дата-время>/<исходный путь>`.
- Лог: `/var/log/debian_init.log`.
- Повторный запуск идемпотентен: неизменившиеся файлы не перезаписываются.
- Одновременный запуск двух копий блокируется (`/run/debian_init.lock`).

## Дополнительные компоненты (`--extras`)

`gitconfig`, `dirs`, `sshperms`, `fzf`, `python` (pipx), `node` (nvm), `docker` (официальный репозиторий, deb822), `zsh` (oh-my-zsh, powerlevel10k, плагины; смена оболочки — по вопросу, по умолчанию нет). `--extras all` — все. Ставятся для пользователя `--extras-user` (по умолчанию `SUDO_USER`).

## Переименование VG: риски

Переименование группы томов корневой ФС — операция, после которой ошибка в `fstab`/`crypttab`/initramfs/GRUB = незагружаемая система. Скрипт:

- показывает diff всех изменяемых файлов и просит подтверждение перед `vgrename`;
- откатывает имя VG и файлы при ошибке до завершения шага;
- обновляет `initramfs` (все ядра) и `grub.cfg`;
- отказывается работать, если `/boot` лежит в той же VG.

Перед запуском на важной машине — снапшот ВМ. После — перезагрузка обязательна.

## Структура

```
install.sh            оркестратор: параметры, режимы, порядок шагов
lib/common.sh         общие функции: лог, dry-run, вопросы, apt, бэкапы, копирование файлов
modules/10-base.sh    preflight, upgrade, packages
modules/20-files.sh   system-files, dotfiles, users
modules/30-identity.sh hostname, identity, lvm
modules/40-optional.sh zabbix, extras
packages/*.list       списки пакетов
files/etc/bash/       системные файлы bash → /etc/bash
files/home/           .bashrc, .tmux.conf → домашние каталоги
docs/readme_tmux.md   шпаргалка по tmux
```

## Ограничения

- Проверено в chroot Debian 13 (debootstrap) без systemd и без LVM. Переименование VG на реальной LVM и welcome-экран под systemd нужно проверить на тестовой ВМ.
- Рассчитано на Debian 12/13. Другие дистрибутивы не поддерживаются.
