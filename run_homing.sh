#!/bin/bash

# Скрипт для сборки и запуска Docker-контейнера

# Имя образа
IMAGE_NAME="webots-homing-planner"

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    echo "Ошибка: Docker не установлен. Пожалуйста, установите Docker и повторите попытку."
    exit 1
fi

# Сборка образа
echo "Сборка образа $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" .

if [ $? -ne 0 ]; then
    echo "Ошибка при сборке образа $IMAGE_NAME"
    exit 1
fi

echo "================================================"
echo "Образ $IMAGE_NAME успешно собран!"
docker images | grep "$IMAGE_NAME"
echo "================================================"

# Имя контейнера
CONTAINER_NAME="homing_planner_container"

# Проверка доступности X-сервера
if [ -z "$DISPLAY" ]; then
    echo "Предупреждение: Переменная DISPLAY не установлена. Графический интерфейс может не работать."
fi

# Разрешаем доступ к X-серверу
xhost +local:docker > /dev/null 2>&1

echo "Запуск контейнера $CONTAINER_NAME из образа $IMAGE_NAME..."

# Определяем параметры GPU
GPU_PARAMS=""
if command -v nvidia-smi &> /dev/null && nvidia-smi > /dev/null 2>&1; then
    GPU_PARAMS="--gpus all"
    echo "Обнаружена NVIDIA GPU, используется аппаратное ускорение"
else
    echo "NVIDIA GPU не обнаружена, используется программный рендеринг"
    GPU_PARAMS="-e LIBGL_ALWAYS_SOFTWARE=0 -e GALLIUM_DRIVER=radeonsi"
fi

# Запускаем контейнер
docker run -it --rm \
    --name "$CONTAINER_NAME" \
    $GPU_PARAMS \
    -e DISPLAY="$DISPLAY" \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev/shm:/dev/shm \
    --device=/dev/dri:/dev/dri \
    --network=host \
    --privileged \
    -v /etc/localtime:/etc/localtime:ro \
    --shm-size=1g \
    "$IMAGE_NAME" \
     bash -c "source /opt/ros/humble/setup.bash && \
             [ -f \"/workspace/install/setup.bash\" ] && source /workspace/install/setup.bash; \
             echo 'Поиск пакета homing_local_planner...'; \
             ros2 pkg prefix homing_local_planner || echo 'Пакет не найден'; \
             echo 'Запуск launch-файла...'; \
             ros2 launch homing_local_planner robot_launch.py"

# Отключаем доступ к X-серверу
xhost -local:docker > /dev/null 2>&1