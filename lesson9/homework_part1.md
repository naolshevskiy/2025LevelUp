## roles/java/tasks/main.yml

```
---
- name: Install Java on Debian-based systems
  become: yes
  apt:
    name: "openjdk-{{ java_version }}-jdk"
    state: present
    update_cache: yes
  when: ansible_os_family == "Debian"

- name: Install Java on RedHat-based systems
  become: yes
  dnf:
    name: "java-{{ java_version }}-openjdk-devel"
    state: present
    update_cache: yes
  when: ansible_os_family == "RedHat"
  ignore_errors: yes

- name: Fallback to yum for older RedHat systems
  become: yes
  yum:
    name: "java-{{ java_version }}-openjdk-devel"
    state: present
  when: ansible_os_family == "RedHat"

- name: Set JAVA_HOME environment variable
  become: yes
  lineinfile:
    path: /etc/environment
    line: 'JAVA_HOME="/usr/lib/jvm/java-{{ java_version }}-openjdk-amd64"'
    state: present
  when: ansible_os_family == "Debian"

- name: Set JAVA_HOME for RedHat systems
  become: yes
  lineinfile:
    path: /etc/environment
    line: 'JAVA_HOME="/usr/lib/jvm/java-{{ java_version }}-openjdk"'
    state: present
  when: ansible_os_family == "RedHat"
  ```

## roles/maven/tasks/main.yml
```
---
- name: Download and install Maven (cross-platform)
  become: yes
  unarchive:
    src: "https://dlcdn.apache.org/maven/maven-3/{{ maven_version }}/binaries/apache-maven-{{ maven_version }}-bin.tar.gz"
    dest: /opt
    remote_src: yes
    creates: "/opt/apache-maven-{{ maven_version }}"

- name: Create symlink for maven
  become: yes
  file:
    src: "/opt/apache-maven-{{ maven_version }}"
    dest: /opt/maven
    state: link
    force: yes

- name: Set M2_HOME and add to PATH
  become: yes
  blockinfile:
    path: /etc/profile.d/maven.sh
    block: |
      export M2_HOME=/opt/maven
      export PATH=${M2_HOME}/bin:${PATH}
    create: yes
    marker: "# {mark} ANSIBLE MANAGED MAVEN ENV"

- name: Reload environment for current session
  shell: source /etc/profile.d/maven.sh
  changed_when: false
  ```

## roles/postgresql/tasks/main.yml
  ```
  ---
- name: Install PostgreSQL on Debian
  become: yes
  apt:
    name: 
      - postgresql
      - postgresql-contrib
    state: present
    update_cache: yes
  when: ansible_os_family == "Debian"

- name: Install PostgreSQL on RedHat
  become: yes
  dnf:
    name: 
      - postgresql-server
      - postgresql-contrib
    state: present
  when: ansible_os_family == "RedHat"
  ignore_errors: yes

- name: Fallback to yum for older RedHat
  become: yes
  yum:
    name: 
      - postgresql-server
      - postgresql-contrib
    state: present
  when: ansible_os_family == "RedHat"

- name: Initialize PostgreSQL database (RedHat only)
  become: yes
  command: postgresql-setup --initdb
  when: ansible_os_family == "RedHat"
  args:
    creates: /var/lib/pgsql/data

- name: Start and enable PostgreSQL service
  become: yes
  service:
    name: postgresql
    state: started
    enabled: yes

- name: Wait for PostgreSQL to accept connections
  become: yes
  wait_for:
    port: 5432
    delay: 5
    timeout: 30

- name: Set PostgreSQL password for 'postgres' user
  become: yes
  become_user: postgres
  postgresql_user:
    name: postgres
    password: "{{ postgres_password }}"
    encrypted: no

- name: Configure PostgreSQL to listen on all addresses
  become: yes
  lineinfile:
    path: "{{ postgresql_conf_path }}"
    regexp: '^#?listen_addresses'
    line: "listen_addresses = '*'"
    backup: yes
  notify: restart postgresql

- name: Allow connections from all IPs (pg_hba.conf)
  become: yes
  blockinfile:
    path: "{{ postgresql_hba_path }}"
    block: |
      host    all             all             0.0.0.0/0               md5
      host    all             all             ::/0                    md5
    marker: "# {mark} ANSIBLE MANAGED"
    insertafter: EOF
  notify: restart postgresql

- name: Create database
  become: yes
  become_user: postgres
  postgresql_db:
    name: "{{ postgres_db_name }}"
    encoding: UTF8
    lc_collate: en_US.UTF-8
    lc_ctype: en_US.UTF-8

- name: Load demo data if file exists
  become: yes
  become_user: postgres
  command: psql {{ postgres_db_name }} < {{ demo_data_path }}
  args:
    chdir: "{{ playbook_dir }}"
  when: demo_data_path is defined and demo_data_path | file_exists
  ```


## roles/nginx/tasks/main.yml
```
---
- name: Install Nginx on Debian
  become: yes
  apt:
    name: nginx
    state: present
    update_cache: yes
  when: ansible_os_family == "Debian"

- name: Install Nginx on RedHat
  become: yes
  dnf:
    name: nginx
    state: present
  when: ansible_os_family == "RedHat"
  ignore_errors: yes

- name: Fallback to yum for older RedHat
  become: yes
  yum:
    name: nginx
    state: present
  when: ansible_os_family == "RedHat"

- name: Start and enable Nginx
  become: yes
  service:
    name: nginx
    state: started
    enabled: yes

- name: Configure Nginx reverse proxy for Spring Boot app
  become: yes
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/sites-available/webbooks
  when: ansible_os_family == "Debian"

- name: Symlink Nginx site (Debian)
  become: yes
  file:
    src: /etc/nginx/sites-available/webbooks
    dest: /etc/nginx/sites-enabled/webbooks
    state: link
    force: yes
  when: ansible_os_family == "Debian"

- name: Use default nginx.conf for RedHat (or template as needed)
  become: yes
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  when: ansible_os_family == "RedHat"

- name: Test Nginx configuration
  become: yes
  command: nginx -t
  register: nginx_test
  changed_when: false

- name: Reload Nginx
  become: yes
  service:
    name: nginx
    state: reloaded
  when: nginx_test.rc == 0
  ```

## roles/nginx/templates/nginx.conf.j2
  ```
{% if ansible_os_family == "Debian" %}
server {
    listen 80;
    server_name {{ domain_name | default('localhost') }};

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
{% else %}

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    server {
        listen 80;
        server_name {{ domain_name | default('localhost') }};

        location / {
            proxy_pass http://localhost:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
{% endif %}
```

## filter_plugins/
```
# filter_plugins/file_filters.py
def file_exists(path):
    import os
    return os.path.exists(path)

class FilterModule(object):
    def filters(self):
        return {
            'file_exists': file_exists
        }
```

## group_vars/all.yml
```
---
java_version: 17
maven_version: "3.9.7"
postgres_password: "securepassword123"
postgres_db_name: "webbooks_db"
domain_name: "localhost"
demo_data_path: "{{ playbook_dir }}/roles/postgresql/files/data.sql"


postgresql_conf_path: "{{ '/etc/postgresql/12/main/postgresql.conf' if ansible_os_family == 'Debian' else '/var/lib/pgsql/data/postgresql.conf' }}"
postgresql_hba_path: "{{ '/etc/postgresql/12/main/pg_hba.conf' if ansible_os_family == 'Debian' else '/var/lib/pgsql/data/pg_hba.conf' }}"
```

## playbook.yml
```
---
- name: Deploy WebBooks Application Stack
  hosts: all
  become: yes
  vars_files:
    - group_vars/all.yml

  roles:
    - java
    - maven
    - postgresql
    - nginx

  handlers:
    - name: restart postgresql
      service:
        name: postgresql
        state: restarted
        ```



## Vagrantfile с Ansible провиженером
```
Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/focal64"  # Ubuntu 20.04


  config.vm.hostname = "webbooks-vm"
  config.vm.network "private_network", ip: "192.168.56.10"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end

  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "ansible/playbook.yml"
    ansible.inventory_path = "ansible/inventory.ini"
    ansible.install = true
    ansible.version = "latest"
    ansible.verbose = "v"
  end


  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 8080, host: 8081

end
```