FROM ubuntu:jammy

# Установка базовых зависимостей
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    locales \
    bash \
    coreutils \
    file \
    binutils \
    curl \
    gnupg2 \
    software-properties-common \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Настройка локали
RUN locale-gen en_US.UTF-8 && \
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Добавление репозитория ROS
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt install -y software-properties-common && add-apt-repository universe -y

# Установка ROS Humble
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ros-humble-desktop-full \
    ros-dev-tools \
    python3-rosdep \
    python3-colcon-common-extensions \
    && rm -rf /var/lib/apt/lists/*

# Установка системных зависимостей для Webots и GUI
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget \
    git \
    build-essential \
    python3-pip \
    nano \
    sudo \
    libgl1-mesa-glx \
    libglu1-mesa \
    libsm6 \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    mesa-utils \
    xvfb \
    libqt5core5a \
    libqt5gui5 \
    libqt5widgets5 \
    libqt5opengl5 \
    libpci3 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-xinerama0 \
    libxcb-xinput0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libvulkan1 \
    mesa-vulkan-drivers \
    libgl1-mesa-dri \
    libgles2-mesa \
    libegl1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Установка Webots из tar-архива
RUN WEBOTS_URL="https://github.com/cyberbotics/webots/releases/download/R2025a/webots-R2025a-x86-64.tar.bz2" && \
    wget $WEBOTS_URL -O /tmp/webots.tar.bz2 && \
    mkdir -p /usr/local/webots && \
    tar -xjf /tmp/webots.tar.bz2 -C /usr/local/webots --strip-components=1 && \
    rm /tmp/webots.tar.bz2

# Настройка рабочего пространства
WORKDIR /workspace
COPY . /workspace

# Перемещаем проект в src
RUN mkdir -p src && \
    mv homing_local_planner src/

# Клонируем webots_ros2
RUN git clone --recurse-submodules https://github.com/cyberbotics/webots_ros2.git src/webots_ros2

# Установка ROS-пакетов, которые являются зависимостями
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    # Основные ROS-пакеты
    ros-humble-desktop-full \
    # Webots ROS 2 пакеты
    ros-humble-webots-ros2 \
    ros-humble-webots-ros2-driver \
    ros-humble-webots-ros2-epuck \
    ros-humble-webots-ros2-tesla \
    ros-humble-webots-ros2-universal-robot \
    ros-humble-webots-ros2-turtlebot \
    # Навигация и планирование
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
    ros-humble-nav2-common \
    ros-humble-nav2-core \
    ros-humble-nav2-util \
    ros-humble-nav2-costmap-2d \
    ros-humble-nav2-msgs \
    ros-humble-slam-toolbox \
    # Дополнительные ROS-пакеты
    ros-humble-graph-msgs \
    ros-humble-rviz-visual-tools \
    ros-humble-xacro \
    ros-humble-robot-state-publisher \
    ros-humble-joint-state-publisher \
    ros-humble-joint-state-publisher-gui \
    ros-humble-tf2-ros \
    ros-humble-nav-msgs \
    ros-humble-sensor-msgs \
    ros-humble-ros-ign-interfaces \
    ros-humble-ament-cmake \
    ros-humble-rclpy \
    ros-humble-tf-transformations \
    ros-humble-tf2-geometry-msgs \
    ros-humble-rclcpp \
    ros-humble-geometry-msgs \
    ros-humble-pluginlib \
    ros-humble-tf2 \
    ros-humble-visualization-msgs \
    ros-humble-nav2-simple-commander \
    ros-humble-cartographer-ros \
    ros-humble-diff-drive-controller \
    ros-humble-ros2-control \
    ros-humble-ros2-controllers \
    ros-humble-turtlebot3* \
    # Дополнительные системные зависимости
    libpci3 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 \
    libxcb-render-util0 libxcb-shape0 libxcb-xinerama0 libxcb-xinput0 \
    libxcb-xkb1 libxkbcommon-x11-0 libopencv-dev libpcl-dev \
    && rm -rf /var/lib/apt/lists/*

# Инициализация и обновление rosdep
RUN rosdep init && \
    rosdep update --rosdistro humble

# Установка ROS-зависимостей через rosdep (только для системных пакетов)
RUN . /opt/ros/humble/setup.sh && \
    rosdep install --from-paths src --ignore-src -y --rosdistro humble --skip-keys="libopencv-dev libpcl-dev" || echo "Незначительные ошибки проигнорированы"

# Сборка проекта
RUN . /opt/ros/humble/setup.sh && \
    colcon build --symlink-install

# Настройка окружения
ENV WEBOTS_HOME=/usr/local/webots \
    DISPLAY=:0 \
    QT_X11_NO_MITSHM=1
    # LD_LIBRARY_PATH=/usr/local/webots/lib:/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

RUN echo "source /opt/ros/humble/setup.bash" >> /etc/bash.bashrc && \
    echo "source /workspace/install/setup.bash" >> /etc/bash.bashrc

# Создаем не-root пользователя
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} devgroup && \
    useradd -m -u ${USER_ID} -g devgroup devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R devuser:devgroup /workspace

# Финальная проверка bash
RUN ldd /bin/bash && \
    file /bin/bash && \
    /bin/bash --version

# Очистка
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Переключаемся на пользователя
USER devuser
WORKDIR /workspace

ENTRYPOINT []
CMD ["/bin/bash"]
