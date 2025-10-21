#!/bin/bash
set -e

read -p "Введите версию Python для установки (например, 3.13.0) [3.13.0]: " PYTHON_VERSION
PYTHON_VERSION=${PYTHON_VERSION:-3.13.0}

PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | awk -F. '{print $1"."$2}')

SRC_DIR="/usr/local/src"
INSTALL_DIR="/opt/python/${PYTHON_VERSION}"

echo "Установка пакетов для сборки Python..."
sudo apt update -y
sudo apt install -y \
  build-essential \
  zlib1g-dev \
  libffi-dev \
  libsqlite3-dev \
  libncurses5-dev \
  libreadline-dev \
  libreadline6-dev \
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
  libtirpc-dev \
  llvm

if apt-cache show libmpdec-dev >/dev/null 2>&1; then
  sudo apt install -y libmpdec-dev
else
  echo "⚠️  libmpdec-dev не найден — пропускаем"
fi

echo "Переход в директорию исходников: $SRC_DIR"
sudo mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

echo "Скачиваем исходники Python $PYTHON_VERSION..."
sudo wget -q --show-progress "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"

echo "Распаковываем архив..."
sudo tar -xzf "Python-${PYTHON_VERSION}.tgz"

echo "Переходим в папку исходников..."
cd "Python-${PYTHON_VERSION}"

echo "Конфигурация сборки..."
./configure \
  --prefix="$INSTALL_DIR" \
  --enable-optimizations \
  --with-ensurepip=install \
  --enable-loadable-sqlite-extensions

echo "Компиляция Python..."
make -j$(nproc)

echo "Установка Python..."
sudo make altinstall

echo "Создаем символические ссылки..."
sudo ln -sf "$INSTALL_DIR/bin/python${PYTHON_MAJOR}" /usr/local/bin/python3
sudo ln -sf "$INSTALL_DIR/bin/pip${PYTHON_MAJOR}" /usr/local/bin/pip3

echo "Проверяем установленный Python и pip..."
python3 --version
pip3 --version

echo "Проверяем ensurepip..."
python3 -c "import ensurepip; print('✅ ensurepip доступен')"

echo "Тестируем venv..."
cd /tmp
python3 -m venv test_venv
test_venv/bin/python -c "import pip; print('✅ venv работает')"
rm -rf test_venv

echo "Удаляем исходники..."
sudo rm -rf "$SRC_DIR/Python-${PYTHON_VERSION}" "$SRC_DIR/Python-${PYTHON_VERSION}.tgz"

echo "Установка Python $PYTHON_VERSION завершена!"
