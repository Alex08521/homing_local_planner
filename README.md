🐳 Инструкция по использованию Docker-контейнера для Homing Local Planner
📋 Предварительные требования
ОС: Linux (рекомендуется Ubuntu 22.04)

Docker: Установка Docker

NVIDIA драйверы (если есть GPU):

```bash
sudo apt install nvidia-driver-535 nvidia-container-toolkit
sudo nvidia-ctk runtime configure
sudo systemctl restart docker
```

X-сервер:

```bash
sudo apt install x11-xserver-utils
xhost +local:docker
```

🚀 Быстрый старт
Клонируйте репозиторий:

```bash
git clone https://github.com/Alex08521/homing_local_planner.git
cd homing_local_planner
```

Соберите Docker-образ:

```bash
chmod +x run_homing.sh  # Даем права на выполнение
./run_homing.sh
```

После сборки автоматически запустится:

- Webots с TurtleBot3

- RViz с визуализацией навигации

- Планировщик homing_local_planner

🔧 Ручное управление контейнером
Запуск интерактивной сессии:

```bash
docker run -it --rm \
    --gpus all \
    -e DISPLAY=$DISPLAY \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev/shm:/dev/shm \
    -v $(pwd):/workspace/src/homing_local_planner \
    --network=host \
    --shm-size=1g \
    webots-homing-planner
```

Основные команды внутри контейнера:

```bash
# Пересборка пакета:
colcon build --symlink-install --packages-select homing_local_planner

# Запуск основной симуляции:
ros2 launch homing_local_planner robot_launch.py

# Тестовый запуск без Webots:
ros2 launch homing_local_planner test_launch.py

# Запуск с разными картами:
ros2 launch homing_local_planner robot_launch.py map:=skir
```

🌍 Доступные карты
Измените параметр map при запуске:

-hospital (по умолчанию)

-office

-town

-skir

-maze

Пример:

```bash
ros2 launch homing_local_planner robot_launch.py map:=office
⚙️ Конфигурация планера
Файлы конфигурации находятся в:
homing_local_planner/config/
```

Основные настройки:

homing_controller.yaml - параметры контроллера

homing_planner.yaml - параметры планировщика

homing_costmap.yaml - настройки costmap

После изменения конфигов пересоберите пакет:

```bash
colcon build --symlink-install --packages-select homing_local_planner
```

🧪 Тестирование
Запуск тестового окружения:

```bash
ros2 launch homing_local_planner test_launch.py
```

Ручная публикация целей:

В RViz нажмите "2D Goal Pose"

Укажите цель на карте

Наблюдайте за поведением планера

🐛 Отладка
Просмотр топиков:

```bash
ros2 topic list
ros2 topic echo /homing_debug
```

Визуализация отладочной информации:

Откройте RViz

Добавьте отображение:

Path (тема: /homing_path)

MarkerArray (тема: /homing_markers)

💡 Советы по использованию
Производительность:

-Для лучшей производительности используйте NVIDIA GPU

-Если нет GPU, добавьте при запуске:

```bash
-e LIBGL_ALWAYS_SOFTWARE=1
```

Кастомизация мира:

Файлы миров Webots: homing_local_planner/worlds/

Чтобы использовать свой мир:

```bash
ros2 launch homing_local_planner robot_launch.py world:=/workspace/src/homing_local_planner/worlds/your_world.wbt
```

Изменение робота:

Модели роботов: homing_local_planner/description/

Измените файл robot.urdf.xacro

🧹 Очистка
Удаление Docker-образа:

```bash
docker rmi webots-homing-planner
```

Очистка системы:

```bash
docker system prune -a
```

⚠️ Возможные проблемы и решения
Проблема: Нет графического вывода
Решение:

```bash
xhost +local:docker
sudo apt install mesa-utils
```

Проблема: Ошибки NVIDIA
Решение:

```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base nvidia-smi
```

Проблема: Ошибки памяти
Решение: Увеличьте shared memory:

```bash
--shm-size=2g  # в docker-run.sh
```

Этот контейнер предоставляет полную среду для работы с homing_local_planner(https://github.com/zengxiaolei/homing_local_planner.git), включая визуализацию в RViz и симуляцию в Webots. Для начала работы достаточно выполнить всего две команды - клонирование репозитория и запуск скрипта! 🚀


## References

[1] Astolfi, A., Exponential Stabilization of a Wheeled Mobile Robot Via Discontinuous
Control, Journal of Dynamic Systems, Measurement, and Control, vol. 121, 1999

[2] C. Rösmann, F. Hoffmann and T. Bertram: Integrated online trajectory planning and optimization in distinctive topologies, Robotics and Autonomous Systems, Vol. 88, 2017, pp. 142–153.

[3] Mobile Robot Course of The Institute of Control Theory and Systems Engineering at TU Dortmund



## License

The *homing_local_planner* package is licensed under the **BSD 3-Clause** license. It depends on other ROS packages, which are listed in the package.xml. They are also BSD licensed.

Some third-party dependencies are included that are licensed under different terms:

- *Eigen*, MPL2 license, [http://eigen.tuxfamily.org](http://eigen.tuxfamily.org/)
- *Boost*, Boost Software License, [http://www.boost.org](http://www.boost.org/)

All packages included are distributed in the hope that they will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
