    docker pull jenkins/jenkins:jdk11
    docker run -d -v jenkins_volume:/var/jenkins_home -p 8080:8080 -p 50000:50000 --name my_jenkins jenkins/jenkins:jdk11
    ip:8080
    docker exec my_jenkins cat /var/jenkins_home/secrets/initialAdminPassword
    
1. [Install docker + docker-compose](https://github.com/m-koleda/guides/blob/main/docker/install-docker-docker-compose.md)  

Now run Jenkins by docker or docker-compose. In two ways used volumes for backup jenkins settings.  

2. Run Jenkins-container by docker  
2.2. Pull jenkins image with preinstall JDK11 from dockerhub   

        docker pull jenkins/jenkins:jdk11

2.3. Run container with need attributes  

    docker run -d -p 8080:8080 -p 50000:50000 --name my_jenkins jenkins/jenkins:jdk11
    # info about running containers
    docker ps

docker run -d -p serverport:containerport -p serverport:containerport --name my_jenkins jenkins/jenkins:jdk11  
-d (detach) - run container in background and print container ID;  
-p (--publish) - publish a container's port(s) to the host;  
8080 port for access to Jenkins web-interface;  
50000 port for access with Jenkins agents;  
--name - assign a name to the container.  

![Screenshot from 2023-01-31 13-50-43](https://user-images.githubusercontent.com/97964258/215740390-ee6cb21d-3879-4a35-af86-aeec6bdb1c6c.png)

Check the Jenkins:

[http://localhost:8080](http://localhost:8080/)  

2.4. Configuring Jenkins
Get Administrator password:

    docker logs my_jenkins
    # or by cat file /var/jenkins_home/secrets/initialAdminPassword in container
    docker exec my_jenkins cat /var/jenkins_home/secrets/initialAdminPassword

Than install suggested pluggins and create first admin user.

2.5. Backup and recovery of Jenkins data in Docker  

The Jenkins image creates a separate VOLUME and attaches it to the container.  
This means that even if you delete the container or image, the volume with the   
data will remain.  
For example, this way we can see the ID of the volume that is mounted at the  
container, as well as the path of its location on the host and in the container:  

    docker inspect my_jenkins | grep 'volume' --after-contex=2

![Screenshot from 2023-01-31 14-02-31](https://user-images.githubusercontent.com/97964258/215745816-b11e837d-a376-4cf1-a223-ec946e344f75.png)


Backup - copy the contents of the volume:

    sudo cp -r /var/lib/docker/volumes/e593bc57c22b66ca25179d03177069af782052a1a705afffdb135dda858b4bef/_data ./jenkins_backup

Copy from backup to Jenkins directory /var/jenkins_home in container my_jenkins:

    docker cp ./jenkins_backup my_jenkins:/var/jenkins_home

We use a separate VOLUME, we can mount it to another container and save all the data:

    docker run -d -p 8082:8080 -v e593bc57c22b66ca25179d03177069af782052a1a705afffdb135dda858b4bef:/var/jenkins_home --name my_jenkins2 jenkins/jenkins:jdk11

You can create a readable name of volume in docker run. Volume will be created automatically:

    docker run -d -p 8083:8080 -v jenkins_volume:/var/jenkins_home --name my_jenkins jenkins/jenkins:jdk11
    
View the volume list:

    docker volume ls
    
VOLUME is not deleted when deleting containers, you can do it yourself.  
Before deleting a volume, you need to delete the containers that use this volume:  

    docker volume rm e593bc57c22b66ca25179d03177069af782052a1a705afffdb135dda858b4bef

3. Run Jenkins via docker-compose  

To launch the container via docker-compose, we create an instruction in yaml format.  
In this instruction, we list the same values as when creating a container normally.  
The only difference is the name of the parameters itself:

    version: '3.7'
    services:
      jenkins:
        image: jenkins/jenkins:latest
        ports:
          - 8080:8080
        container_name: my_jenkins
        ## connect the volume
        #volumes:
        #  - jenkins_volume:/var/jenkins_home
    ## create volumes
    #volumes:
    #  jenkins_volume:
    #    # if volume wasn't create
    #    driver: local
    #    # if volume war created not in compose
    #    external: true
    #    name: jenkins_volume
    
Run Jenkins via docker-compose:

    docker-compose up -d

By default, docker-compose searches for a file named 'docker-compose.yml'. If this name  
is different for you, use -f parameter:

    docker-compose -f my_jenkins_docker_compose.yml up -d

Stop containers by docker-compose:

    # will stop the containers
    docker-compose -f 'test_jenkins.yml' stop
    # will stop and delete the containers
    docker-compose -f 'test_jenkins.yml' down



https://fixmypc.ru/post/zapuskaem-jenkins-vnutri-docker-i-compose-i-bekapom/
