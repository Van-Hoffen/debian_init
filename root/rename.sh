#!/bin/bash

# Функция для вывода ошибок и выхода
error_exit() {
    echo "Ошибка: $1" >&2
    exit 1
}

# Функция для проверки наличия команды
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        error_exit "Команда '$cmd' не найдена. Убедитесь, что она установлена."
    fi
}

# Проверка доступности необходимых внешних команд
required_commands=("cat" "lvdisplay" "vgrename" "sed" "grep" "update-initramfs" "update-grub")
for cmd in "${required_commands[@]}"; do
    check_command "$cmd"
done

# Проверка прав суперпользователя (root)
if [ "$(id -u)" -ne 0 ]; then
    error_exit "Этот скрипт должен быть запущен от имени root."
fi

# Получаем текущее имя хоста
oldhostname=$(cat /etc/hostname) || error_exit "Не удалось прочитать /etc/hostname."
echo "Текущее имя хоста: $oldhostname"

# Запрашиваем у пользователя новое имя хоста
read -p "Введите новое имя хоста: " newhostname

# Валидация нового имени хоста (пример: только буквы, цифры и дефисы)
if [[ ! "$newhostname" =~ ^[a-zA-Z0-9-]+$ ]]; then
    error_exit "Недопустимое имя хоста. Разрешены только буквы, цифры и дефисы."
fi

# Удаляем дефисы из нового имени хоста для упрощения названия группы томов
newvg=${newhostname//-}

# Находим группу томов, в которой находится логический том root
vg=$(lvdisplay -C | awk '$1=="root" {print $2}')
if [ -z "$vg" ]; then
    error_exit "Группа томов для логического тома root не найдена."
fi

echo "Старое имя группы томов: $vg"
echo "Новое имя группы томов: $newvg"

# Запрос подтверждения от пользователя ДО внесения любых изменений в систему
echo
echo "ВНИМАНИЕ! Будет изменено имя хоста на '$newhostname' и переименована LVM группа '$vg' -> '$newvg'."
read -p "Вы уверены, что хотите продолжить? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Отмена выполнения скрипта. Изменения не внесены."
    exit 0
fi

# Создаем резервные копии только существующих конфигурационных файлов
backup_files=("/etc/hostname" "/etc/hosts" "/etc/fstab" "/boot/grub/grub.cfg" "/etc/initramfs-tools/conf.d/resume")
for file in "${backup_files[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup" || error_exit "Не удалось создать резервную копию файла $file."
        echo "Создана резервная копия: ${file}.backup"
    fi
done

# Переименовываем группу томов
echo
echo "Переименование группы томов LVM..."
if [[ "$vg" == *"-"* ]]; then
    # Если текущее имя группы томов содержит дефисы
    newvg_temp="${newhostname//-}"
    vgrename "$vg" "$newvg_temp" || error_exit "Не удалось переименовать группу томов."
    # Заменяем дефисы на двойные дефисы для соответствия правилам LVM
    vg=${vg//-/--}
else
    # Если текущее имя группы томов не содержит дефисов
    vgrename "$vg" "$newvg" || error_exit "Не удалось переименовать группу томов."
fi
echo "Группа томов успешно переименована."

echo
echo "Изменение имени хоста в конфигурационных файлах..."

# Обновляем /etc/hostname
if [ -f /etc/hostname ]; then
    sed -i "s/${oldhostname}/${newhostname}/g" /etc/hostname || error_exit "Не удалось обновить /etc/hostname."
fi

# Обновляем /etc/hosts
if [ -f /etc/hosts ]; then
    sed -i "s/${oldhostname}/${newhostname}/g" /etc/hosts || error_exit "Не удалось обновить /etc/hosts."
fi

echo "Имя хоста успешно изменено."

# Обновляем конфигурационные файлы, чтобы отразить изменение имени группы томов (только существующие)
files_to_update=("/etc/fstab" "/boot/grub/grub.cfg" "/etc/initramfs-tools/conf.d/resume")
for file in "${files_to_update[@]}"; do
    if [ -f "$file" ]; then
        sed -i "s/${vg}/${newvg}/g" "$file" || error_exit "Не удалось обновить $file."
        echo "Файл $file обновлен."
    fi
done

# Проверяем обновленные файлы
echo
echo "Проверяем изменения в конфигурационных файлах:"

check_update() {
    local description="$1"
    local file="$2"
    local pattern="$3"
    if [ ! -f "$file" ]; then
        echo "$description: файл $file отсутствует (пропущено)."
        return 0
    fi
    echo "$description:"
    if grep -q "$pattern" "$file"; then
        echo "  [OK] Обновление прошло успешно."
    else
        echo "  [WARN] Обновление не найдено в файле: $file" >&2
    fi
}

check_update "Обновление fstab" "/etc/fstab" "$newvg"
check_update "Обновление grub.cfg" "/boot/grub/grub.cfg" "$newvg"
check_update "Обновление resume" "/etc/initramfs-tools/conf.d/resume" "$newvg"
check_update "Обновление имени хоста" "/etc/hostname" "$newhostname"
check_update "Обновление hosts" "/etc/hosts" "$newhostname"

# Обновляем initramfs, чтобы отразить изменения
echo
echo "Обновление initramfs..."
update-initramfs -c -k all || error_exit "Не удалось обновить initramfs."
echo "initramfs успешно обновлен."

# Обновляем конфигурацию загрузчика GRUB
echo "Обновление конфигурации загрузчика GRUB..."
update-grub || error_exit "Не удалось обновить конфигурацию GRUB."
echo "Конфигурация GRUB успешно обновлена."

echo
echo "Скрипт выполнен успешно. Рекомендуется перезагрузить систему, чтобы изменения вступили в силу."
