Конфиг файлы сборки приложения 
webbooks-ansible/roles/nginx/templates/nginx.conf.j2
```
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://{{ hostvars['back'].ansible_host }}:{{ app_port }};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

webbooks-ansible/roles/nginx/handlers/main.yml
```
- name: reload nginx
  systemd:
    name: nginx
    state: reloaded
```

webbooks-ansible/roles/nginx/tasks/main.yml
```
- name: Install Nginx
  apt:
    name: nginx
    state: present
    update_cache: yes

- name: Configure reverse proxy
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/webbooks
  notify: reload nginx

- name: Enable site
  file:
    src: /etc/nginx/sites-available/webbooks
    dest: /etc/nginx/sites-enabled/webbooks
    state: link

- name: Remove default site
  file:
    path: /etc/nginx/sites-enabled/default
    state: absent
  notify: reload nginx
```

webbooks-ansible/roles/postgres/vars/main.yml
```
postgresql_version: "12"
```

webbooks-ansible/roles/postgres/files/data.sql
```
DROP TABLE IF EXISTS genres CASCADE;

CREATE TABLE genres (
                        id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                        name varchar NOT NULL UNIQUE
);

DROP TABLE IF EXISTS authors CASCADE;

CREATE TABLE authors (
    --                        обязательные поля
                         id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                         name varchar NOT NULL UNIQUE,
                         dateOfBirth varchar NOT NULL,
    --                         необязательные поля
                         dateOfDeath varchar,
                         description varchar
);

INSERT INTO authors(name, dateOfBirth, dateOfDeath, description) VALUES
    ('Джейн Остен', '1939', '1945', 'Информация о писателе.Информация о писателе.Информация о писателе.Информация о писателе.'),
    ('Джордж Оруэлл', '1939', '1945', ''),
    ('Фрэнсис Скотт Фицджеральд', '1939', '1945', 'Информация о писателе.Информация о писателе.Информация о писателе.Информация о писателе.'),
    ('Луиза Мэй Олкотт', '1939', '1945', ''),
    ('Маргарет Митчелл', '1939', '', ''),
    ('Дж. Д. Сэлинджер', '1939', '', 'Информация о писателе.Информация о писателе.Информация о писателе.Информация о писателе.'),
    ('Марк Твен', '1939', '1945', ''),
    ('С. Л. Клайв', '1939', '', '');

DROP TABLE IF EXISTS books CASCADE;

CREATE TABLE books (
--                        обязательные поля
                       id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                       name varchar NOT NULL UNIQUE,
                       genre_id int NOT NULL REFERENCES genres(id) ON DELETE CASCADE,
                       author_id int NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
                       status varchar NOT NULL,
                       year int NOT NULL check ( year > 0  AND year < 2050),
--                         необязательные поля
                       description varchar

);

DROP TABLE IF EXISTS clients CASCADE;

CREATE TABLE clients (
                         id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
--      обязательные поля
                         name varchar NOT NULL UNIQUE,
                         age int NOT NULL check (age > 0 AND age < 111),
                         email varchar NOT NULL UNIQUE,
                         sex varchar NOT NULL,
                         phoneNumber varchar UNIQUE NOT NULL,
--      необязательные поля
                         deliveryAddress varchar,
                         description varchar,
                         favoriteGenre varchar

);

INSERT INTO genres (name) VALUES
                              ('Роман'),
                              ('Антиутопия'),
                              ('Драма'),
                              ('Сатира'),
                              ('Фэнтези'),
                              ('Ужасы'),
                              ('Комедия');

INSERT INTO books (name, genre_id, author_id, year,description, status) VALUES
                                                     ('Гордость и предубеждение', (SELECT id FROM genres WHERE name = 'Роман'), (SELECT id FROM authors WHERE name = 'Джейн Остен'), 1813, '', 'Свободна'),
                                                     ('1984', (SELECT id FROM genres WHERE name = 'Антиутопия'), (SELECT id FROM authors WHERE name = 'Джордж Оруэлл'), 1948, '', 'Свободна'),
                                                     ('Великий Гэтсби', (SELECT id FROM genres WHERE name = 'Драма'), (SELECT id FROM authors WHERE name = 'Фрэнсис Скотт Фицджеральд'), 1926, '', 'Свободна'),
                                                     ('Маленькие женщины', (SELECT id FROM genres WHERE name = 'Драма'), (SELECT id FROM authors WHERE name = 'Луиза Мэй Олкотт'), 1868, '', 'Взята'),
                                                     ('Унесенные ветром', (SELECT id FROM genres WHERE name = 'Драма'), (SELECT id FROM authors WHERE name = 'Маргарет Митчелл'), 1936, '', 'Свободна'),
                                                     ('Скотный двор', (SELECT id FROM genres WHERE name = 'Сатира'), (SELECT id FROM authors WHERE name = 'Джордж Оруэлл'), 1945, '', 'Свободна'),
                                                     ('Над пропастью во ржи', (SELECT id FROM genres WHERE name = 'Роман'), (SELECT id FROM authors WHERE name = 'Дж. Д. Сэлинджер'), 1951, '', 'Свободна'),
                                                     ('Приключения Гекльберри Финна', (SELECT id FROM genres WHERE name = 'Роман'), (SELECT id FROM authors WHERE name = 'Марк Твен'), 1884, '', 'Свободна'),
                                                     ('Хроники Нарнии', (SELECT id FROM genres WHERE name = 'Фэнтези'), (SELECT id FROM authors WHERE name = 'С. Л. Клайв'), 1950, '', 'Взята');

INSERT INTO clients (name, age, email, sex, phoneNumber,favoriteGenre, description) VALUES
                                                             ('Березнев Никита', 20, 'bernikcooldude@yandex.ru', 'Мужчина', '89031111112', '-', '-'),
                                                             ('Дин Норрис', 34, 'dnorris@yandex.ru', 'Мужчина', '89031111114', '-', '-'),
                                                             ('Мишель Томпсон', 16, 'mthompson@yandex.ru', 'Женщина', '89031111115', '-', '-'),
                                                             ('Дженнифер Лоуренз', 16, 'jlawrense@gmail.ru', 'Женщина', '89031111611', '-', '-'),
                                                             ('Скарлетт Йохансон', 16, 'scarlet@gmail.ru', 'Женщина', '89031111117', '-', '-'),
                                                             ('Крис Эванс', 35, 'kevans@gmail.ru', 'Мужчина', '89031111811', '-', '-'),
                                                             ('Хью Джекман', 20, 'hughy@gmail.ru', 'Мужчина', '89031111511', '-', '-'),
                                                             ('Мэтью Макконахи', 20, 'mattewmc@mail.ru', 'Мужчина', '89231111111', '-', '-');

DROP TABLE IF EXISTS orders CASCADE;

CREATE TABLE orders (
                        id int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
                        client_id int NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
                        book_id int NOT NULL UNIQUE REFERENCES books(id) ON DELETE CASCADE
);

INSERT INTO orders (client_id, book_id) VALUES
((SELECT id from clients WHERE name = 'Хью Джекман'), (SELECT id from books WHERE name = 'Маленькие женщины')),
((SELECT id from clients WHERE name = 'Хью Джекман'), (SELECT id from books WHERE name = 'Хроники Нарнии'));
```

webbooks-ansible/roles/postgres/handlers/main.yml
```
- name: restart postgresql
  systemd:
    name: postgresql
    state: restarted
```

webbooks-ansible/roles/postgres/tasks/main.yml
```
- name: Install PostgreSQL 12
  apt:
    name:
      - postgresql-12
      - postgresql-client-12
      - python3-psycopg2
    state: present
    update_cache: yes

- name: Configure PostgreSQL to listen on all interfaces
  lineinfile:
    path: /etc/postgresql/12/main/postgresql.conf
    regexp: '^#?listen_addresses'
    line: "listen_addresses = '*'"
  notify: restart postgresql

- name: Set PostgreSQL password for 'postgres' user
  postgresql_user:
    name: "{{ db_user }}"
    password: "{{ db_password }}"
    login_user: postgres
    login_password: "{{ db_password }}"
  become: yes
  become_user: postgres

- name: Create database
  postgresql_db:
    name: "{{ db_name }}"
    owner: "{{ db_user }}"
    login_user: postgres
    login_password: "{{ db_password }}"
  become: yes
  become_user: postgres

- name: Copy demo data SQL file
  copy:
    src: files/data.sql
    dest: /tmp/data.sql

- name: Load demo data into DB
  shell: psql -U {{ db_user }} -d {{ db_name }} -f /tmp/data.sql
  environment:
    PGPASSWORD: "{{ db_password }}"
  become: yes
  become_user: postgres
```

webbooks-ansible/roles/webbooks/templates/application.properties.j2
```
DB.driver=org.postgresql.Driver
DB.url=jdbc:postgresql://{{ hostvars['db'].ansible_host }}:5432/{{ db_name }}
DB.user={{ db_user }}
DB.password={{ db_password }}
```

webbooks-ansible/roles/webbooks/templates/webbooks.service.j2
```
[Unit]
Description=WebBooks Spring Boot Application
After=network.target

[Service]
Type=simple
User=nikita
WorkingDirectory=/opt/{{ app_name }}
ExecStart=/usr/bin/java -jar target/{{ app_name }}-*.jar
Restart=always

[Install]
WantedBy=multi-user.target
```

webbooks-ansible/roles/webbooks/tasks/main.yml
```
- name: Install Maven
  apt:
    name: maven
    state: present
    update_cache: yes

- name: Copy application source code
  copy:
    src: /home/nikita/2025-07-example/apps/webbooks/
    dest: /opt/{{ app_name }}
  register: app_copied

- name: Ensure app directory is owned by app_user
  file:
    path: /opt/{{ app_name }}
    owner: "{{ app_user }}"
    group: "{{ app_user }}"
    recurse: yes

- name: Ensure mvnw is executable
  file:
    path: /opt/{{ app_name }}/mvnw
    mode: '0755'

- name: Check if JAR file exists
  stat:
    path: /opt/{{ app_name }}/target/{{ app_name }}-*.jar
  register: jar_check

- name: Build application with Maven (skip tests)
  command: ./mvnw package -Dmaven.test.skip=true
  args:
    chdir: /opt/{{ app_name }}
  environment:
    JAVA_HOME: "/usr/lib/jvm/java-17-openjdk-amd64"
  when: not jar_check.stat.exists

- name: Create systemd service for WebBooks
  template:
    src: webbooks.service.j2
    dest: /etc/systemd/system/{{ app_name }}.service

- name: Reload systemd and start service
  systemd:
    name: "{{ app_name }}"
    daemon_reload: yes
    enabled: yes
    state: restarted
```

webbooks-ansible/roles/jdk/tasks/main.yml
```
- name: Install OpenJDK 17
  apt:
    name: openjdk-17-jdk
    state: present
    update_cache: yes

- name: Set JAVA_HOME in /etc/environment
  lineinfile:
    path: /etc/environment
    line: 'JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd68"'
    create: no

- name: (Optional) Ensure JAVA_HOME is available for current tasks
  set_fact:
    java_home: "/usr/lib/jvm/java-17-openjdk-amd64"
```

webbooks-ansible/site.yml
```
---
- name: Deploy WebBooks application
  hosts: all
  become: yes
  roles:
    - { role: jdk, when: "'back' in group_names" }
    - { role: postgres, when: "'db' in group_names" }
    - { role: nginx, when: "'front' in group_names" }
    - { role: webbooks, when: "'back' in group_names" }
```

webbooks-ansible/group_vars/all.yml
```
# Общие параметры
app_name: webbooks
app_version: "1.0"
app_port: 8080
db_name: webbooks_db
db_user: postgres
db_password: "secure_password"
```

webbooks-ansible/inventory/hosts.ini
```
[db]
db ansible_host=192.168.227.130 ansible_ssh_pipelining=true

[back]
back ansible_host=192.168.227.128

[front]
front ansible_host=192.168.227.129

[all:vars]
ansible_user=nikita
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

webbooks-ansible/tasks/main.yml
```
- name: Configure application.properties
  template:
    src: application.properties.j2
    dest: /opt/{{ app_name }}/src/main/resources/application.properties
```
