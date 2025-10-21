#!/bin/bash
set -e  # Выход при ошибке

# Запрос версии у пользователя с дефолтным значением
read -p "Введите версию Python для установки (например, 3.13.0) [3.13.0]: " PYTHON_VERSION
PYTHON_VERSION=${PYTHON_VERSION:-3.13.0}

# Получаем Major.Minor часть (например, из 3.13.0 -> 3.13)
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | awk -F. '{print $1"."$2}')

SRC_DIR="/usr/local/src"
INSTALL_DIR="/opt/python/${PYTHON_VERSION}"

echo "Установка пакетов для сборки Python..."
sudo apt update -y
sudo apt install -y \
  zlib1g-dev \
  libffi-dev \
  libsqlite3-dev \
  libncurses5-dev \
  libreadline-dev \
  libdb-dev \
  libgdbm-dev \
  libgdbm-compat-dev \
  libssl-dev \
  libbz2-dev \
  libexpat1-dev \
  liblzma-dev \
  libzstd-dev \
  uuid-dev \
  tk-dev \
  libnsl-dev \
  libtirpc-dev

# Добавляем libmpdec-dev, если он доступен в репозитории
if apt-cache show libmpdec-dev >/dev/null 2>&1; then
  PKGS+=(libmpdec-dev)
else
  echo "⚠️  libmpdec-dev не найден в репозиториях — пропускаем"
fi

echo "Переход в директорию исходников: $SRC_DIR"
cd "$SRC_DIR"

echo "Скачиваем исходники Python $PYTHON_VERSION..."
sudo wget -q --show-progress "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"

echo "Распаковываем архив..."
sudo tar -xzf "Python-${PYTHON_VERSION}.tgz"

echo "Переходим в папку исходников..."
cd "Python-${PYTHON_VERSION}"

echo "Конфигурация сборки..."
./configure --prefix="$INSTALL_DIR" --enable-optimizations

echo "Компиляция Python (это займет некоторое время)..."
make -j$(nproc)

echo "Установка Python..."
sudo make altinstall

echo "Создаем символические ссылки..."
sudo ln -sf "$INSTALL_DIR/bin/python${PYTHON_MAJOR}" /usr/local/bin/python3
sudo ln -sf "$INSTALL_DIR/bin/pip${PYTHON_MAJOR}" /usr/local/bin/pip3

echo "Проверяем установленный Python и pip..."
python3 --version
pip3 --version

echo "Удаляем исходники..."
sudo rm -rf "$SRC_DIR/Python-${PYTHON_VERSION}" "$SRC_DIR/Python-${PYTHON_VERSION}.tgz"

echo "Установка Python $PYTHON_VERSION завершена!"
