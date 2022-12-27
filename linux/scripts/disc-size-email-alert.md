#### Задача:
Написать скрипт, который будет выполнять проверку состояния диска и, если места меньше чем 85%, то высылать алерт на почту.  
Для отправки писем прямиком из консоли можно использовать ssmtp клиент. 

#### Подготовка  

Для начала устанавливаем утилиту для отправки почты.  

В Debian / Ubuntu:  

    apt-get install mailutils  

В CentOS / Red Hat:

    yum install mailx
    
После установки появится окно с предложением настроить postfix mail-server. Выбираем Internet Site  
\* если выдает ошибку: mail: cannot send message: process exited with a non-zero status,  
то заново настраиваем с помощью команды sudo dpkg-reconfigure postfix  

#### Проверка почты  

Можно отправить сообщение следующей командой:  

    echo "Test text" | mail -s "Test title" yours_e-mail@yandex.ru

\* в данном примере будет отправлено письмо на электронный адрес yours_e-mail@yandex.ru с темой Test title и телом письма — Test text.

#### Тело скрипта:  

    #!/bin/bash
    # Указываем название диска для проверки
    namedisc="/dev/sda1"
    hostname=`cat /proc/sys/kernel/hostname`
    
    # Задаем переменную, где вычисляем свободное место на диске /dev/sda1
    usespace=`df -m | grep "$namedisc" | awk '{print $5}' | awk '{print substr ($ 0, 1, length($0)-1 ) }'`
    echo "The disk $namedisk is $usespace $ full"
    
    # Если свободного места меньше 20%, то отправляем письмо на e-mail.
    
    if [ $usespace -gt 85 ];
    then
    echo "Warning!!! On the Server $hostname running out of space on your hard drive $namedisc. Used space - "$usespace"%" | mail -s "Used Spase on the Server" yours_e-mail@ya.ru
    fi

![image](https://user-images.githubusercontent.com/97964258/209674484-9587a235-a46f-44b9-887d-b03af403dec1.png)

Использованные ресурсы:  
<https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-18-04>  
<https://www.dmosk.ru/miniinstruktions.php?mini=mail-shell#prepare>  
<https://linux-freebsd.ru/linux/linux-pro4ee/skript-proverki-svobodnogo-diskovogo-prostranstva-v-linux/>  
<https://ciksiti.com/ru/chapters/4016-removing-characters-from-string-in-bash--linux-hint>
