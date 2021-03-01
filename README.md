# Instalación de un cluster de KUBERNETES en AZURE utilizando Terraform y Ansible

Este proyecto pretende la creación de la infraestructura necesaria para la creación de un cluster de Kubernetes en MS-Azure.
Para ello, la creación de las VM se realizará mediante TERRAFORM (1 master y 2 workers). De forma que el despliegue del cluster se realizará con Ansible

Posteriormente se desplegarán sobre dicho cluster una instancia de NGINX y una de TOMCAT para demostrar su funcionamiento


### Preparativos

Lo siguiente debe ser configurado para poder realizar la instalación

* Una cuenta de Azure (puede ser educativa) pero con una restricción de, al menos 6 vcpu
* Una máquina física o virtual (este proyecto se ha ejecutado correctamente sobre Ubuntu 20.04) sobre la que lanzar los scripts
* Terraform y Ansible instalados sobre dicha máquina (ver documentación de dichos productos para obtener información)
    * https://learn.hashicorp.com/tutorials/terraform/install-cli
    * https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
* AZ CLI instalado en la máquina (ver documentación)
    * https://docs.microsoft.com/es-es/cli/azure/install-azure-cli-linux?pivots=apt



### Instalación detallada

A. Preparación TERRAFORM

  1. Clonar el repositorio
  2. Ejecutar az login para obtener acceso a nuestra instancia. Se abrirá una pantalla en un navegador web para poder introducir nuestras credenciales
  3. Una vez identificados, se puede cerrar el navegador, y el comando az cli habrá devuelto datos de nuestra instancia. IMPORTANTE, copiar el valor del campo "id" del JSON devuelto
  4. Desde la carpeta raíz del proyecto, navegar a ./terraform/red y editar el fichero variables.tf para establecer el valor de la variable "my_public_ip" a la IP pública de la máquina. Para ello
      1. Para ello, utilizar un servicio de tipo "https://www.cual-es-mi-ip.net/"
  5. Desde la carpeta raíz del proyecto, navegar a ./terraform/nodos y editar el fichero variables.tf para establecer el valor de la variable "admin_user" al usuario que se desee
  6. Desde la carpeta raíz del proyecto, navegar a ./terraform/globales y editar el fichero variables.tf para establecer el valor de la variable "subscription-id" al valor correspondiente
      1. Ese valor es el obtenido en el punto 3, al ejecutar az cli

<br/>
B. Creación de infraestructura en AZURE

  1. Abrir una consola de sh y, desde la carpeta raíz del proyecto, navegar a ./terraform/nodos. Una vez allí
      1. Ejecutar 'terraform init' 
      2. Ejecutar 'terraform plan'
      3. Ejecutar 'terraform apply --auto-approve'

<br/>
C. Preparación ANSIBLE
 
  1. Obtener las IP públicas de los tres nodos (master, worker-1 y worker-2). Para ello, dirigirse a la consola de Azure y consultar el campo "Direccion IP Publica" de cada vm
  2. Agregar las siguientes 3 lineas al fichero /etc/hosts (linux/mac) o c:\Windows\System32\Drivers\etc\hosts (Windows) de la máquina local de trabajo
      1. IP-master   	master
      2. IP-worker-1   worker-1
      3. IP-worker-2  	worker-2
     <br/>Donde las tres IP son las obtenidas en el punto anterior
  3. Eliminar las entradas de master, worker-1 y worker-2 del fichero "known_hosts" de la máquina local, para ello ejecutar desde una terminal sh
      1. cd /home/<usuario> (donde usuario es el usuario sobre el que está realizando la instalación
      1. ssh-keygen -f "./.ssh/known_hosts" -R "master" 
      2. ssh-keygen -f "./.ssh/known_hosts" -R "worker-1" 
      3. ssh-keygen -f "./.ssh/known_hosts" -R "worker-2" 
  4. Desde la carpeta raíz del proyecto, navegar a ./ansible y editar el fichero "hosts"; y modificar el valor de todas las entradas de "ansible_user" por el usuario especificado en A.5
  5. Desde la carpeta raíz del proyecto, navegar a ./ansible y editar el fichero "ssh.cfg"; y modificar el valor de todas las entradas de "User" por el usuario especificado en A.5
  6. Desde la carpeta raíz del proyecto, navegar a ./ansible/playbooks y editar el fichero "env_variables", cambiando el valor de  "master", "worker_1" y "worker_2" por las ip privadas de los nodos
      1. Para obtener la ip privada de cada nodo, dirigirse a la consola de Azure y consultar el campo "Direccion IP Privada" de cada vm
  7. Desde la carpeta raíz del proyecto, navegar a ./ansible/playbooks y editar el fichero "env_variables", cambiando el valor de  "nfs_path" por la ruta compartida por nfs entre los nodos
      
 
<br/> 
D. Instalación de un entorno cliente-servidor de nfs

   1. NOTA: Estos pasos se pueden ejecutar en cualquier momento, antes o después de los puntos E y F. (Como requisito, se ha de haber ejecutado el punto C, como mínimo)
   2. Abrir una consola de sh y, desde la carpeta raíz del proyecto, navegar a ./ansible. Una vez allí
       1. Ejecutar 'ansible-playbook playbooks/nfsServidor.yml -i hosts'
           1. El script presenta por salida estándar la comprobación final del estado del servicio linux de nfs. Se deberá obtener una última línea del estilo "Started NFS server and services"
       2. Ejecutar 'ansible-playbook playbooks/nfsClientes.yml -i hosts'
   3. Para comprobar el correcto funcionamiento, ir al directorio indicado por nfs_path (ver punto C.7) de worker-1 o worker-2 (ssh) y ejecutar "sudo touch prueba.txt". 
       1. El fichero será visible desde cualquiera de las otras dos máquinas
 
<br/>      
E. Creación del cluster de Kubernetes con ANSIBLE

  1. Abrir una consola de sh y, desde la carpeta raíz del proyecto, navegar a ./ansible. Una vez allí
      1. Ejecutar 'ansible-playbook playbooks/preinstalacion.yml -i hosts' 
      2. Ejecutar 'ansible-playbook playbooks/creacionUsuario.yml -i hosts'
      3. Ejecutar 'ansible-playbook playbooks/dependencias.yml -i hosts'
      4. Ejecutar 'ansible-playbook playbooks/master.yml -i hosts'
      5. Ejecutar 'ansible-playbook playbooks/workers.yml -i hosts'
  2. La ejecución del último script genera como salida una comprobación del estado del cluster (kubectl get nodes -o wide). Se debe comprobar que las últimas líneas muestren los 3 nodos en estado READY (como en el ejemplo a continuación)

            "NAME       STATUS   ROLES                  AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME",
            "master     Ready    control-plane,master   13m   v1.20.4   10.0.2.6      <none>        Ubuntu 18.04.5 LTS   5.4.0-1039-azure   docker://19.3.6",
            "worker-1   Ready    <none>                 61s   v1.20.4   10.0.2.4      <none>        Ubuntu 18.04.5 LTS   5.4.0-1039-azure   docker://19.3.6",
            "worker-2   Ready    <none>                 74s   v1.20.4   10.0.2.5      <none>        Ubuntu 18.04.5 LTS   5.4.0-1039-azure   docker://19.3.6"

<br/>
F. Despliegue de NGINX y TOMCAT con ANSIBLE

  1. Abrir una consola de sh y, desde la carpeta raíz del proyecto, navegar a ./ansible. Una vez allí
      1. Ejecutar 'ansible-playbook playbooks/deploy.yml -i hosts' 
  2. Este script, además, obtiene por salida estándar los datos de los pods y servicios creados, de forma que se pueda obtener la información para poder ejecutar las aplicaciones
  
            "NAME                           READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES",
            "nginx-6799fc88d8-9d8z7         1/1     Running   0          37s   172.16.1.3   worker-2   <none>           <none>",
            "tomcatinfra-7f58bf9cb8-cvvw5   1/1     Running   0          26s   172.16.2.3   worker-1   <none>           <none>"



            "NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE   SELECTOR",
            "kubernetes    ClusterIP   10.96.0.1       <none>        443/TCP        33m   <none>",
            "nginx         NodePort    10.105.18.164   <none>        80:30336/TCP   36s   app=nginx",
            "tomcatinfra   NodePort    10.108.242.73   <none>        80:30794/TCP   25s   app=tomcatinfra"

   3. En este caso, nginx está desplegado en el puerto 30336 del worker-2. Mientras que tomcat está desplegado en el puerto 30794 del worker-1.
   4. Para entrar en las aplicaciones, abrir un navegador de internet, indicando la información vista en los puntos anteriores (se incluye ejemplo)
       1. NGINX: http://<ip_publica_worker_2>:30336/
       2. TOMCAT: http://<ip_publica_worker_1>:30794/


