1. Установить docker + docker compose:
  
        curl -fsSL http://get.docker.com -o get-docker.sh  
        sudo sh get-docker.sh  
        sudo usermod -aG docker $USER  
        su $USER  
        
        sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
