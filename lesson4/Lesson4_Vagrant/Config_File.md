# 1) packer/webbooks.json

```console
{
  "builders": [
    {
      "type": "virtualbox-iso",
      "vm_name": "webbooks-vm",
      "guest_os_type": "Ubuntu_64",
      "iso_url": "http://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso",
      "iso_checksum": "sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      "boot_command": [
        "<enter><wait10>",
        "autoinstall ds=nocloud-net;s=http://<ip>:<port>/ ---<enter>"
      ],
      "boot_wait": "10s",
      "ssh_username": "vagrant",
      "ssh_password": "vagrant",
      "ssh_wait_timeout": "10000s",
      "shutdown_command": "sudo shutdown -P now",
      "disk_size": 10000
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "script": "../scripts/install-tools.sh",
      "execute_command": "chmod +x {{ .Path }} && sudo {{ .Path }}"
    },
    {
      "type": "shell",
      "script": "../scripts/setup-webbooks.sh",
      "execute_command": "chmod +x {{ .Path }} && sudo {{ .Path }}"
    }
  ],
  "post-processors": [
    {
      "type": "vagrant",
      "output": "../boxes/webbooks.box"
    }
  ]
}
```

----------------
# 2) scripts/install-tools.sh
```console
#!/bin/bash
set -e

echo "Обновление системы..."
apt-get update

echo "Установка OpenJDK 17"
apt-get install -y openjdk-17-jdk

echo "Установка Maven"
apt-get install -y maven

echo "Установка PostgreSQL 12"
apt-get install -y postgresql-12 postgresql-contrib-12

echo "Установка пароля для пользователя postgres"
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'password';"

echo "Настройка PostgreSQL на прослушивание всех интерфейсов"
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/12/main/postgresql.conf
echo "host all all 0.0.0.0/0 md5" | sudo tee -a /etc/postgresql/12/main/pg_hba.conf

echo "Перезапуск PostgreSQL"
sudo systemctl restart postgresql

echo "Базовые инструменты установлены"
```
-----

# 3) scripts/setup-webbooks.sh
```
#!/bin/bash
set -e

APP_DIR="/home/vagrant/webbooks"
DB_NAME="webbooks"

echo "Клонирование репозитория Webbooks"
cd /home/vagrant || exit
git clone https://github.com/levelup-devops/2025-07-example.git 2>/dev/null || echo "Репозиторий уже существует"
cd "$APP_DIR" || exit

echo "Создание базы данных $DB_NAME"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"

echo "Восстановление демо-данных"
sudo -u postgres psql "$DB_NAME" < src/main/resources/data.sql

echo "Настройка application.properties"
cat > src/main/resources/application.properties << EOF
DB.driver=org.postgresql.Driver
DB.url=jdbc:postgresql://localhost:5432/$DB_NAME
DB.user=postgres
DB.password=password
EOF

echo "Сборка приложения с Maven"
./mvnw clean package -DskipTests

echo "Запуск Webbooks..."
nohup java -jar target/*.jar > webbooks.log 2>&1 &

echo "Приложение запущено. Логи: $APP_DIR/webbooks.log"
echo "Доступно по: http://localhost:8080"
```
----
# 4) vagrant/Vagrantfile
```
Vagrant.configure("2") do |config|
  config.vm.box = "webbooks/production"
  config.vm.box_url = "../boxes/webbooks.box"

  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end

  config.vm.provision "shell", path: "../scripts/install-tools.sh"
  config.vm.provision "shell", path: "../scripts/setup-webbooks.sh"
end
```

